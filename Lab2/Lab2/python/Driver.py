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

import math
import random

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

    def wait_bytes(self, n, timeout=0.5):
        """
        Waits until at least n bytes are in the queue, without the 1 s sleep of get_data.
        :self: uart object.
        :n: bytes expected.
        :timeout: max seconds to wait.
        """
        t0 = time.time()
        while len(self._rx_buffer) < n and time.time() - t0 < timeout:
            time.sleep(0.0005)

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

    def _send_receive_cmd(self, tx0, tx1, quiet=False):
        """
        Sends MDRS inputs data and checks received MDRS outputs data.
        Output information is logged as info unless quiet is set.
        :self: mdrs object.
        :tx0: first byte of data (check script header for details)
        :tx1: first byte of data (check script header for details)
        :quiet: if True the outputs are not logged as info.
        :return: (result, remainder, loadx, loady, ready, error), None if bytes are missing.
        """
        self.uart.flush()
        self.uart.send_byte(tx0)
        self.uart.send_byte(tx1)
        self.uart.wait_bytes(5)
        b0 = self.uart.get_data()
        b1 = self.uart.get_data()
        b2 = self.uart.get_data()
        b3 = self.uart.get_data()
        b4 = self.uart.get_data()
        if None in [b0, b1, b2, b3, b4]:
            received_count = 5 - [b0, b1, b2, b3, b4].count(None)
            log.error(f"Expecting 5 bytes from UART, got {received_count}. Status unknown.")
            return None
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
            if not quiet:
                log.info(f"Result = {result} ({(result & 0x3FF):#06x})")
                log.info(f"Remainder =  {remainder} ({(remainder & 0x3FF):#06x})")
                log.info(f"LoadX = {loadx}")
                log.info(f"LoadY = {loady}")
                log.info(f"Ready = {ready}")
                log.info(f"Error = {error}")
            self.uart.send_byte(1)
            self.uart.send_byte(0)
            return (result, remainder, loadx, loady, ready, error)

    def load(self, op=0, data=0, quiet=False):
        """
        Sends MDRS load (1), trigger (1) and op/data values. Everything else in zero.
        :self: mdrs object.
        :data: data value to MDRS (10 bits)
        :quiet: if True the outputs are not logged as info.
        :return: same tuple as _send_receive_cmd.
        """
        t0 = ((data & 0x07) << 5) | ((op & 0x3) << 3) | 0x5
        t1 = (data & 0x3F8) >> 2
        return self._send_receive_cmd(t0, t1, quiet)

# --------------------------------------------------------------
# Auto check. modos: 
#   0 mult 
#   1 div
#   2 sqrt
#   3 square
#   4 todas las operaciones (casos que deberian pasar),
#   5 todas las operaciones (casos que deberian dar error).
# Segundo argumento se usa n como: 
#       0 = todos los casos del modo
#       n > 0 = n casos al azar por operacion.
# El historial se guarda en auto.log y mdrs.log
# ------------------------------------------------------------------
    OP_NAMES = ["mult", "div", "sqrt", "square"]

    @staticmethod
    def _expected(op, x, y=0):
        """
        Modelo de referencia (operandos de 10 bits con signo).
        :return: (result, remainder), o None si la operacion debe dar error.
        """
        match op:
            case 0:
                r = x * y
                return (r, 0) if -512 <= r <= 511 else None
            case 1:
                if y == 0 or (x == -512 and y == -1):
                    return None
                q = int(x / y)                      # trunca hacia cero
                return (q, x - q * y)
            case 2:
                if x < 0:
                    return None
                q = math.isqrt(x)
                return (q, x - q * q)
            case 3:
                return (x * x, 0) if x * x <= 511 else None

    def _cases(self, op, must_fail, n):
        """
        Todos los (x, y) de una operacion que deben pasar (must_fail=False)
        o que deben dar error (True). Si n > 0 devuelve solo n al azar.
        """
        if op in (2, 3):
            pool = [(x, 0) for x in range(-512, 512)]
        else:
            pool = [(x, y) for x in range(-512, 512) for y in range(-512, 512)]
        cases = [c for c in pool if (self._expected(op, *c) is None) == must_fail]
        return random.sample(cases, n) if 0 < n < len(cases) else cases

    def auto(self, mode=4, n=200, imprimir=1):
        """
        Corre la automatizacion e imprime cada caso fallido (tambien en auto.log).
        :mode: 0 mult, 1 div, 2 sqrt, 3 square, 4 todas (deben pasar), 5 todas (deben dar error).
        :n: 0 prueba TODOS los casos del modo (div puede tardar horas).
            n > 0 prueba n casos al azar por operacion.
        :imprimir: 0 imprime en terminal cada caso (operacion, operandos, result, remainder y flags).
                   1 no imprime los casos, solo los fallidos y el resumen (por defecto).
        """
        match mode:
            case 0 | 1 | 2 | 3:
                ops = [mode]
            case 4 | 5:
                ops = [0, 1, 2, 3]
            case _:
                print("mode: 0 mult, 1 div, 2 sqrt, 3 square, 4 todas, 5 casos de error")
                return
        cases = [(o, x, y) for o in ops for (x, y) in self._cases(o, mode == 5, n)]
        random.shuffle(cases)                       # mezcla ops para detectar datos residuales
        fallos = hechos = 0
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "auto.log")
        old_level = log.level
        log.setLevel(logging.WARNING)               # evita llenar mdrs.log con cada byte
        with open(path, "a", encoding="utf-8") as f:
            def say(msg):
                print(msg)
                f.write(msg + "\n")
            say(f"=== {time.strftime('%Y-%m-%d %H:%M:%S')}  auto(mode={mode}, n={n})  {len(cases)} casos")
            try:
                for o, x, y in cases:
                    if o in (0, 1):
                        self.load(o, x, quiet=True)     # primer operando
                        r = self.load(o, y, quiet=True) # segundo operando, trae el resultado
                    else:
                        r = self.load(o, x, quiet=True)
                    hechos += 1
                    exp = self._expected(o, x, y)
                    if r is None:
                        ok = False
                    elif exp is None:
                        ok = r[5] == 1
                    else:
                        ok = r[5] == 0 and (r[0], r[1]) == exp
                    caso = f"{self.OP_NAMES[o]}({x}, {y})" if o < 2 else f"{self.OP_NAMES[o]}({x})"
                    obtenido = ("sin respuesta" if r is None
                                else f"result={r[0]} remainder={r[1]} loadX={r[2]} loadY={r[3]} "
                                     f"ready={r[4]} error={r[5]}")
                    if imprimir == 0:
                        print(f"{caso} -> {obtenido}")
                    if not ok:
                        fallos += 1
                        esperado = "error" if exp is None else f"result={exp[0]} remainder={exp[1]}"
                        say(f"CASO FALLIDO: {caso}  esperado: {esperado}  obtenido: {obtenido}")
            except KeyboardInterrupt:
                say("Detenido por el usuario")
            finally:
                log.setLevel(old_level)
            say(f"{hechos - fallos} de {hechos} casos correctos")


def main():
    print("RUN AS A LIBRARY")
    input("Press Enter to exit")


if __name__ == "__main__":
    main()