def f1(a: int, b: int) -> int:
    return a + b


def f2(a: int, b: int, op: str) -> int:
    result = None
    if op == "addition":
        result = f1(a, b)
    else:
        print("Operation is not supported")
    return result
