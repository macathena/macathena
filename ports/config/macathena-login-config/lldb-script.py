from __future__ import print_function

# LLDB script to log DirectoryServices calls made by Directory Utility
# 
# Run me as:
#
# lldb --one-line 'script exec(open("lldb-script.py").read())' /System/Library/CoreServices/Applications/Directory\ Utility.app/Contents/MacOS/Directory\ Utility

from CoreFoundation import *
import os

# print(lldb.frame.registers[0].GetChildMemberWithName('rdx'))
# nsd = lldb.frame.registers[0].GetChildMemberWithName('rcx')
# nsd = nsd.Cast(lldb.target.FindFirstType('NSData').GetPointerType())
# error_ref = lldb.SBError()
# b = nsd.GetValueForExpressionPath('->_bytes').GetValueAsUnsigned(error_ref)
# length = nsd.GetValueForExpressionPath('->_length').GetValueAsUnsigned(error_ref)
# data = lldb.process.ReadMemory(b, length, error_ref)
# print(data)

# $rdi is the first argument. The object receiving the method invocation in ObjC.
# $rsi is the second argument. The selector being sent (aka, the _cmd variable).
# $rdx is the third argument. The first argument of an ObjC method invocation if it uses one.
# $rcx is the fourth argument. The second argument of an ObjC method.
# $r8 is the fifth.
# $r9 is the sixth.

plformats = {
    kCFPropertyListXMLFormat_v1_0: "XML",
    kCFPropertyListBinaryFormat_v1_0: "Binary",
    kCFPropertyListOpenStepFormat: "OpenStep",
}

def get_data(frame, register):
    data = 'nil'
    if frame.reg[register]:
        b = frame.EvaluateExpression('(void*)[(NSData*)$%s bytes]' % register).unsigned
        length = frame.EvaluateExpression('(int)[(NSData*)$%s length]' % register).unsigned
        error_ref = lldb.SBError()
        if not length:
            return '0 bytes'
        data = frame.thread.process.ReadMemory(b, length, error_ref)
        # If there's an authenticator, strip off the first 0x20 bytes
        authenticator = data[0:1] not in (b'<', b'b')
        if authenticator:
            data = data[0x20:]
        plist, format, err = CFPropertyListCreateWithData(None, data, 0, None, None)
        if not err:
            data = "%s plist %s" % (plformats.get(format), plist)
        if authenticator:
            data = "Authenticator, %s" % (data,)
    return data

def print_return(frame, bp_loc, session):
    print("->", get_data(frame, 'rax'))

def ODNode_customCall_sendData_enter(frame, bp_loc, session):
    # me read `(void*)[((NSData*)$rcx) bytes]` -c `(size_t)[((NSData*)$rcx) length]`
    nodename = frame.EvaluateExpression('[(ODNode*)$rdi nodeName]').GetSummary()
    callnum = frame.reg['rdx'].unsigned
    print("[<ODNode %s> customCall:0x%x sendData:%s error:%s]" % (
        nodename, callnum, get_data(frame, 'rcx'), frame.reg['r8']))
    target = frame.thread.process.target
    retaddr = frame.reg['rsp'].Cast(target.FindFirstType('void').GetPointerType().GetPointerType()).Dereference().unsigned
    b = target.BreakpointCreateByAddress(retaddr)
    b.SetOneShot(True)
    b.SetScriptCallbackFunction("print_return")
    b.SetAutoContinue(True)
    # nsd = nsd.Cast(lldb.target.FindFirstType('NSData').GetPointerType())
    # if nsd:
    #     error_ref = lldb.SBError()
    #     b = nsd.GetValueForExpressionPath('->_bytes').GetValueAsUnsigned(error_ref)
    #     length = nsd.GetValueForExpressionPath('->_length').GetValueAsUnsigned(error_ref)
    #     data = lldb.process.ReadMemory(b, length, error_ref)
    #     print(data)
    # else:
    #     print("Null data")

b = lldb.target.BreakpointCreateByName("-[ODNode customCall:sendData:error:]")
b.SetScriptCallbackFunction("ODNode_customCall_sendData_enter")
b.SetAutoContinue(True)

def ODCAction_sendConfig_enter(frame, bp_loc, session):
    # - (id)sendConfig:(id)arg1 responseDict:(id *)arg2 nodeName:(id)arg3 customCallCode:(long long)arg4;
    config = frame.EvaluateExpression('[(NSDictionary*)$rdx description]').description
    responseDict = frame.EvaluateExpression('(NSDictionary**)$rcx')
    nodeName = frame.EvaluateExpression('(NSString*)$r8').summary
    code = frame.EvaluateExpression('(long long)$r9')
    print("[ODCAction sendConfig:%s responseDict:%s nodeName:%s customCallCode:0x%x]" % (
        config, responseDict, nodeName, code.unsigned))
b = lldb.target.BreakpointCreateByName("-[ODCAction sendConfig:responseDict:nodeName:customCallCode:]")
b.SetScriptCallbackFunction("ODCAction_sendConfig_enter")
b.SetAutoContinue(True)

lldb.target.LaunchSimple([], None, os.getcwd())
