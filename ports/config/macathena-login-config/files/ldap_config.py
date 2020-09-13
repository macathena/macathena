import CoreFoundation
import CFOpenDirectory
from PyObjCTools import Conversion

s, _ = CFOpenDirectory.ODSessionCreate(None, None, None)
node, _ = CFOpenDirectory.ODNodeCreateWithName(None, s, "/Configure", None)
plist_from_file = Conversion.deserializePropertyList(open('FILESPATH/macathena.plist', 'rb').read())
plist_data = Conversion.serializePropertyList(plist_from_file)
plist_data_with_auth = CoreFoundation.NSData(bytes(0x20) + plist_data)
CFOpenDirectory.ODNodeCustomCall(node, 0x18697, plist_data_with_auth, None)
search_node, _ = CFOpenDirectory.ODNodeCreateWithName(None, s, "/Search", None)
plist_data2 = Conversion.serializePropertyList(Conversion.propertyListFromPythonCollection(["/LDAPv3/ldap-too.mit.edu"]), format='binary')
plist_data2_with_auth = CoreFoundation.NSData(bytes(0x20) + plist_data2)
CFOpenDirectory.ODNodeCustomCall(search_node, 0x1bc, plist_data2_with_auth, None)
