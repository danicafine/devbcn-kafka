class Transaction(object):
    __slots__ = [
        "transaction_id",
        "card_id",
        "user_id",
        "purchase_id",
        "store_id"
    ]

    @staticmethod
    def get_schema():
        with open('./avro/transaction.avsc', 'r') as handle:
            return handle.read()
    
    def __init__(self, transaction_id, card_id, user_id, purchase_id, store_id):
        self.transaction_id = transaction_id
        self.card_id        = card_id
        self.user_id        = user_id
        self.purchase_id    = purchase_id
        self.store_id       = store_id

    @staticmethod
    def dict_to_transaction(obj, ctx=None):
        return Transaction(
                obj['transaction_id'],
                obj['card_id'],
                obj['user_id'],
                obj['purchase_id'],
                obj['store_id']

            )

    @staticmethod
    def transaction_to_dict(transaction, ctx=None):
        return Transaction.to_dict(transaction)

    def to_dict(self):
        return dict(
                    transaction_id = self.transaction_id,
                    card_id        = self.card_id,
                    user_id        = self.user_id,
                    purchase_id    = self.purchase_id,
                    store_id       = self.store_id
                )