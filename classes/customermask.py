class CustomerMask(object):
    __slots__ = [
        "registertime",
        "userid",
        "regionid"
    ]
    
    @staticmethod
    def get_schema():
        with open('./avro/customermask.avsc', 'r') as handle:
            return handle.read()
    
    def __init__(self, registertime, userid, regionid):
        self.registertime = registertime
        self.userid       = userid
        self.regionid     = regionid

    @staticmethod
    def dict_to_customermask(obj, ctx=None):
        return CustomerMask(
                obj['registertime'],
                obj['userid'],    
                obj['regionid']  
            )

    @staticmethod
    def customermask_to_dict(customer, ctx=None):
        return CustomerMask.to_dict(customer)

    def to_dict(self):
        return dict(
                    registertime = self.registertime,
                    userid       = self.userid,
                    regionid     = self.regionid
                )