import time
import serial

PORT = "COM4"  # Ajustar al puerto de tu FPGA
BAUD = 115200

def main():
    passed = 0
    failed = 0

    with serial.Serial(PORT, BAUD, bytesize=8, parity=serial.PARITY_ODD,
                       stopbits=serial.STOPBITS_TWO, timeout=0.5) as ser:
        for v in range(0, 256):              # todos los valores 0x00 a 0xFF
            ser.reset_input_buffer()
            ser.write(bytes([v]))
            eco = ser.read(1)

            if eco == bytes([v]):
                passed += 1
                print(f"PASS: enviado '{chr(v)}' (0x{v:02X}) -> eco '{chr(eco[0])}' (0x{eco[0]:02X})")
            else:
                failed += 1
                recibido = f"'{chr(eco[0])}' (0x{eco[0]:02X})" if eco else "sin respuesta"
                print(f"FAIL: enviado '{chr(v)}' (0x{v:02X}) -> eco {recibido}")

            time.sleep(0.01)                 # pequeño espacio entre bytes

    print()
    print("======================================")
    print("     UART ECHO TEST FINISHED          ")
    print("======================================")
    print(f" Total   : {passed + failed}")
    print(f" Passed  : {passed}")
    print(f" Failed  : {failed}")
    print("======================================")
    print(" RESULT: ALL TESTS PASSED" if failed == 0 else " RESULT: TEST FAILED")

if __name__ == "__main__":
    main()