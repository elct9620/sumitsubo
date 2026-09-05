# A Charge is settled here.
# Each of these lines is a comment of its own.


class Charge:
    """A docstring is a string the language evaluates, not a comment."""

    # @contract Charge.settle
    def settle(self, at, note=None, tag: str = "x", *rest, key=1, **opts):
        return at > 0

    @staticmethod
    def open(amount):
        return Charge()


def recorded(a, /, b, *, c):
    pass


def typed(x: int) -> bool:
    return True


class Outer:
    class Inner:
        def deep(self):
            pass


LIMIT = 10
# A comment nothing follows.
