# Python driver for MDRS project
# Description: This module is sends data through UART to be interpreted as MDRS inputs and reads
#              bytes from uart to get outputs of it.
#					Tx expected format is as follows:
# 					BYTE | 7 bit | 6 bit | 5 bit | 4 bit | 3 bit | 2 bit | 1 bit | 0 bit
# 					  0  |   data_lower_3_bits   |      op       |  Load |  Rsvd |Trigger
# 					  1  |                 data_higher_7_bits                    |   0
#					Rx data expected format is as follows:
# 					BYTE | 7 bit | 6 bit | 5 bit | 4 bit | 3 bit | 2 bit | 1 bit | 0 bit
# 					  0  |   data_lower_3_bits   |      op       |  Load |  Rsvd |Trigger
# 					  1  |                 data_higher_7_bits                    |   0
# 					  2  |                    result_lower_8_bits                    
# 					  3  |              reminder_lower_6_bits            |result_higher_2_bits 
# 					  4  | error | ready | loadY | loadX |      reminder_higher_4_bits
# Author: Santiago Miguel Segovia Cazares
# Date: 03/13/2023
# Version: 1.4
# Release notes:
# 		1.0: Initial version
# 		1.1: Several bug fixes.
# 		1.2: Added message if UART rx data is not complete.
# 		1.3: Pretty format to result and remainder. Bug fix in 2-complement conversion
# 		1.4: Removed Start behavior, now load charges data and op
import threading
import logging
import serial
import time
import sys
import os

TIMEOUT = 1

def setLog():
    """
    Logger settings. Debug lines extra in log file. Stream up to info data
    """
    logger = logging.getLogger('mdrs')
    logger.setLevel(logging.DEBUG)
    fh = logging.FileHandler('mdrs.log')
    fh.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    formatter = logging.Formatter('%(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(fh)
    logger.addHandler(ch)
    return logger
    
log = setLog()

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
    
    def send_byte(self, byte):
        """
        Sends a single byte through uart.
        :self: uart object.
        :byte: byte to be transmitted.
        """
        log.debug(f">> {hex(byte)}")
        self._ser.write(bytearray([byte]))

    def flush(self):
        """
        Removes already received data from queue.
        :self: uart object.
        """
        self._rx_buffer = []

    def get_data(self):
        """
        Gets data received (first byte from queue).
        :self: uart object.
        :return: got value or None if nothing is received
        """
        if len(self._rx_buffer) > 0:
            return self._rx_buffer.pop(0)
        time.sleep(TIMEOUT)
        if len(self._rx_buffer) > 0:
            return self._rx_buffer.pop(0)
        else:
            return None

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
                log.debug(f"<< {hex(int_val)}")
                self._rx_buffer.append(int_val)
    
    def send_list(self, list):
        """
        Sends a list of bytes through uart.
        :self: uart object.
        :list: list of bytes to be transmitted.
        """
        for byte in list:
            self.send_byte(byte)


class MDRS:

    def __init__(self, port="COM3"):
        """
        MDRS constructor. Uart settings fixed to BR 19200 and parity ODD
        :self: mdrs object to be returned.
        :port: COM or tty (linux) port to be used to communicate with.
        """
        self.uart = UART(port, 115200, serial.PARITY_ODD)

    def _send_receive_cmd(self, tx0, tx1):
        """
        Sends MDRS inputs data and checks received MDRS outputs data.
        Output information is logged as info, nothing is returned.
        :self: mdrs object.
        :tx0: first byte of data (check script header for details)
        :tx1: first byte of data (check script header for details)
        """
        self.uart.flush()
        self.uart.send_byte(tx0)
        self.uart.send_byte(tx1)
        b0 = self.uart.get_data()
        b1 = self.uart.get_data()
        b2 = self.uart.get_data()
        b3 = self.uart.get_data()
        b4 = self.uart.get_data()
        if None in [b0, b1, b2, b3, b4]:
            received_count = 5 - [b0, b1, b2, b3, b4].count(None)
            log.error(f"Expecting 5 bytes from UART, got {received_count}. Status unknown.")
        else:
            if not (b0 == tx0 and b1 == tx1):
                log.error(f"Echo did not match {tx0} {tx1} vs {b0} {b1}")
            result = ((b3 & 0x3) << 8) | b2
            if result >= 0x200:
                result -= 0x400
            remainder = ((b4 & 0xF) << 6) | (b3 & 0xFC) >> 2
            if remainder >= 0x200:
                remainder -= 0x400
            loadx = (b4 >> 4) & 1
            loady = (b4 >> 5) & 1
            ready = (b4 >> 6) & 1
            error = (b4 >> 7) & 1
            log.info(f"Result = {result} ({(result & 0x3FF):#06x})")
            log.info(f"Remainder =  {remainder} ({(remainder & 0x3FF):#06x})")
            log.info(f"LoadX = {loadx}")
            log.info(f"LoadY = {loady}")
            log.info(f"Ready = {ready}")
            log.info(f"Error = {error}")
            self.uart.send_byte(1)
            self.uart.send_byte(0)

    def load(self, op=0, data=0):
        """
        Sends MDRS load (1), trigger (1) and op/data values. Everything else in zero.
        :self: mdrs object.
        :data: data value to MDRS (10 bits)
        """
        t0 = ((data & 0x07) << 5) | ((op & 0x3) << 3) | 0x5
        t1 = (data & 0x3F8) >> 2
        self._send_receive_cmd(t0, t1)


def main():
    print("RUN AS A LIBRARY")
    input("Press Enter to exit")


if __name__ == "__main__":
    main()
