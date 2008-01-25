import DNS

DNS.DiscoverNameServers()

dnsreq = DNS.Request(qtype="txt")

class HesiodParseError(Exception):
    pass

class HesiodLookup:
    """A generic Hesiod lookup"""
    def __init__(self, name, type, realm="athena.mit.edu"):
        if "@" in name:
            name, realm = name.rsplit("@", 1)
        self.dnsname = ("%s.%s.ns.%s" % (name, type, realm))
        self.dnsresult = dnsreq.req(name=self.dnsname)
        self.parseRecords()
    def parseRecords(self):
        self.entries = []
        for answer in self.dnsresult.answers:
            if answer['name'] == self.dnsname:
                if isinstance(answer['data'],list):
                    self.entries.extend(answer['data'])
                else:
                    self.entries.append(answer['data'])
    def getRawEntries(self):
        return self.entries

class FilsysLookup(HesiodLookup):
    def __init__(self, name, realm="athena.mit.edu"):
        HesiodLookup.__init__(self, name, "filsys", realm)
    def parseRecords(self):
        HesiodLookup.parseRecords(self)
        self.filsysPointers = []
        if len(self.entries) > 1:
            multiRecords = True
        else:
            multiRecords = False
        for entry in self.entries:
            priority = 0
            if multiRecords:
                entry, priority = entry.rsplit(" ", 1)
                priority = int(priority)
            parts = entry.split(" ")
            type = parts[0]
            if type == 'AFS':
                self.filsysPointers.append({'type': type, 'location': parts[1], 'mode': parts[2], 'mountpoint': parts[3], 'priority': priority})
            elif type == 'NFS':
                self.filsysPointers.append({'type': type, 'remote_location': parts[1], 'server': parts[2], 'mode': parts[3], 'mountpoint': parts[4], 'priority': priority})
            elif type == 'ERR':
                parts = entry.split(" ", 1)
                self.filsysPointers.append({'type': type, 'message': parts[1], 'priority': priority})
            elif type == 'UFS':
                self.filsysPointers.append({'type': type, 'device': parts[1], 'mode': parts[2], 'mountpoint': parts[3], 'priority': priority})
            elif type == 'LOC':
                self.filsysPointers.append({'type': type, 'location': parts[1], 'mode': parts[2], 'mountpoint': parts[3], 'priority': priority})
            else:
                raise HesiodParseError("Unknown filsys type: "+type)
        self.filsysPointers.sort(key=lambda x: x['priority'])
    def getFilsys(self):
        return self.filsysPointers
