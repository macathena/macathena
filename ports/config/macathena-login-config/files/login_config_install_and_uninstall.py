import argparse
import CoreFoundation
import CFOpenDirectory
from PyObjCTools import Conversion


def save_config(session, node_name, plist, custom_call):
    node, error = CFOpenDirectory.ODNodeCreateWithName(None, session,
                                                       node_name, None)
    if error:
        raise OSError(error)
    plist_data = Conversion.serializePropertyList(plist)
    # when run as root the authorization bits are just 20 null bytes
    plist_data_with_auth = CoreFoundation.NSData(bytes(0x20) + plist_data)
    _, error = CFOpenDirectory.ODNodeCustomCall(node, custom_call,
                                                plist_data_with_auth, None)
    if error:
        raise OSError(error)


def uninstall(session):
    # make the search path empty again
    save_config(
        session,
        "/Search",
        Conversion.propertyListFromPythonCollection([]),
        0x1bc,
    )
    # delete ldap-too.mit.edu from the list of servers
    save_config(
        session, "/Configure",
        Conversion.propertyListFromPythonCollection(
            "/LDAPv3/ldap-too.mit.edu"), 0x18698)


def install(session, args):
    # add ldap-too.mit.edu as a server with the config in macathena.plist
    plist = Conversion.deserializePropertyList(
        open('FILESPATH/macathena.plist', 'rb').read())
    if args.network_home_dir:
        plist = edit_plist_mapping(plist, 'NFSHomeDirectory',
                                   'apple-user-homeDirectory')
    if args.bash:
        plist = edit_plist_mapping(plist, 'UserShell', '#/bin/bash')
    save_config(session, "/Configure", plist, 0x18697)
    # add ldap-too.mit.edu to the search path
    save_config(
        session, "/Search",
        Conversion.propertyListFromPythonCollection(
            ["/LDAPv3/ldap-too.mit.edu"]), 0x1bc)


def edit_plist_mapping(plist, key, value):
    plist_dict = Conversion.pythonCollectionFromPropertyList(plist)
    plist_dict['mappings']['recordtypes']['dsRecTypeStandard:Users'][
        'attributetypes']['dsAttrTypeStandard:' + key]['native'] = value
    new_plist = Conversion.propertyListFromPythonCollection(plist_dict)
    return new_plist


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--install', dest='install', action='store_true')
    parser.add_argument('--uninstall', dest='install', action='store_false')
    parser.add_argument('--network-home-dir',
                        dest='network_home_dir',
                        action='store_true')
    parser.add_argument('--bash', dest='bash', action='store_true')
    parser.set_defaults(install=True)
    parser.set_defaults(network_home_dir=False)
    parser.set_defaults(bash=False)
    args = parser.parse_args()
    session, error = CFOpenDirectory.ODSessionCreate(None, None, None)
    if error:
        raise OSError(error)
    if args.install:
        install(session, args)
    else:
        uninstall(session)
