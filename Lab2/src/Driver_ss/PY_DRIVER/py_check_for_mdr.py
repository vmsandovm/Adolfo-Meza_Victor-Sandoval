succ = True
try:
    import os
except:
    succ = False
    print("os was not imported!")
try:
    import sys
except:
    succ = False
    print("sys was not imported!")
try:
    import serial
except:
    succ = False
    print("serial was not imported!")
try:
    import logging
except:
    succ = False
    print("logging was not imported!")
try:
    import threading
except:
    succ = False
    print("threading was not imported!")
if succ:
    print("Your setup is ready to deliver P2!!! Congrats.")
else:
    print("Your setup is NOT ready. Check missing libraries")
input("Press enter to exit")