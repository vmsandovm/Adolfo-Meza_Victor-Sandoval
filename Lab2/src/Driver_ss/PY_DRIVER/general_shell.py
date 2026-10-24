# Python driver for MDR project
# Description: General shell
# Author: Santiago Miguel Segovia Cazares
# Date: 10/10/2023
# Version: 1.1
# Release notes:
# 		1.0: Initial version
# 		1.1: General bug fixes and test
import threading
import logging
import serial
import time
import math
import sys
import os

TIMEOUT = 1


class UART:
    """
    Uart class is used to simplify pyserial access and have independent threads for tx and rx
    """
    def __init__(self, port, br, parity):
        """
        UART constructor.
        :self: uart object to be returned.
        :port: COM or tty (linux) port to be used to communicate with.
        :port: Baudrate value in baudios.
        :parity: Parity value from serial: serial.PARITY_ODD,
                 serial.PARITY_EVEN, serial.PARITY_NONE
        """
        self._ser = serial.Serial(port, br, timeout=TIMEOUT, parity=parity)
        self._rx_buffer = []
        self._listening = True
        rx_task = threading.Thread(target=self._get_byte, args=[])
        rx_task.start()
    
    def send_string(self, line):
        for c in line:
            self.send_byte(ord(c))
        self.send_byte(ord("\n"))
            
    
    def send_byte(self, byte):
        """
        Sends a single byte through uart.
        :self: uart object.
        :byte: byte to be transmitted.
        """
        self._ser.write(bytearray([byte]))

    def flush(self):
        """
        Removes already received data from queue.
        :self: uart object.
        """
        self._rx_buffer = []


    def _get_byte(self):
        """
        Function to be used in separated thread. Will fill a queue (list) with
        received data from uart.
        :self: uart object.
        :return: got value or None if nothing is received
        """
        while self._listening:
            byte_val = self._ser.read(1)
            int_val = int.from_bytes(byte_val, "big")
            if len(str(byte_val)) > 3:
                self._rx_buffer.append(int_val)
                if int_val == ord("\n"):
                    line = ""
                    for i in self._rx_buffer:
                        line += chr(i)
                    print("\r<< " + line + ">> ", end="")
                    self.flush()
    



def run_shell(port=3):
    # Use parity even serial.PARITY_EVEN
    u = UART(f"COM{port}", 9600, serial.PARITY_ODD)
    exit = False
    while not exit:
        line = input(">> ")
        if (line == "quit()"):
            u._listening = False
            u._ser.close()
            exit = True
        else:
            u.send_string(line)
    

def main():
    port = 3 if len(sys.argv) == 1 else sys.argv[1]
    run_shell(port)


if __name__ == "__main__":
    main()
