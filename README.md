# I2C Communication Using FSM in Verilog

This project implements a complete **I2C Master-Slave communication system** in Verilog using **Finite State Machines (FSMs)**. It simulates a real-world I2C bus with full support for **start**, **addressing**, **read/write**, **ACK/NACK**, **data transfer**, and **stop** conditions.

---

## 🧠 Key Features

- ✅ FSM-based **I2C Master** controller
- ✅ FSM-based **I2C Slave** responder
- ✅ 7-bit addressing support
- ✅ Read (`rw = 1`) and Write (`rw = 0`) operations
- ✅ Fully synchronized `SCL` and bidirectional `SDA` handling
- ✅ Uses **tri-state logic** for `SDA` line
- ✅ Verilog **Testbench** included
- ✅ **Top module** integrates both master and slave
- ✅ Timing aligned to simulate realistic I2C delays

---

## 📂 Files Overview

| File Name               | Description                                      |
|------------------------|--------------------------------------------------|
| `i2c_master_fsm.v`     | Master FSM logic: start, address, read/write     |
| `i2c_slave_fsm.v`      | Slave FSM logic: address match, ack, data reply  |
| `i2c_top.v`            | Top-level module connecting master and slave     |
| `i2c_master_fsm_tb.v`  | Testbench to verify I2C functionality             |

---

## ⚙️ I2C Protocol Overview

- **Start Condition**: SDA goes low while SCL is high  
- **Address + RW**: 7-bit slave address + 1-bit read/write
- **ACK/NACK**: Slave sends ACK (0) or NACK (1)
- **Data Phase**: 8-bit data sent by master or received from slave
- **Stop Condition**: SDA goes high while SCL is high

---

## ⏱️ Timing

The clock used in this implementation is a **100 MHz** system clock. The I2C timing is emulated by counting 125 clock cycles (~1.25 µs) to simulate standard I2C speed (~400 kHz SCL).

---

## 🧪 Testbench

The testbench simulates:

- A **write** transaction to the slave with dummy data (`8'hA5`)
- A **read** transaction to receive 8-bit data from the slave

```verilog
trigger = 1;
rw = 0; // Write
din = 8'hA5;

...

trigger = 1;
rw = 1; // Read
