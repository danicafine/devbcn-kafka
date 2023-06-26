class Customer(object):
    __slots__ = [
        "registertime",
        "userid",
        "regionid",
        "gender"
    ]
    
    @staticmethod
    def get_schema():
        with open('./avro/customer.avsc', 'r') as handle:
            return handle.read()
    
    def __init__(self, registertime, userid, regionid, gender):
        self.registertime = registertime
        self.userid       = userid
        self.regionid     = regionid
        self.gender       = gender

    @staticmethod
    def dict_to_customer(obj, ctx=None):
        return Customer(
                obj['registertime'],
                obj['userid'],    
                obj['regionid'], 
                obj['gender']   
            )

    @staticmethod
    def customer_to_dict(customer, ctx=None):
        return Customer.to_dict(customer)

    def to_dict(self):
        return dict(
                    registertime = self.registertime,
                    userid       = self.userid,
                    regionid     = self.regionid,
                    gender       = self.gender
                )