# GNSS-augmentation
Using low-cost GNSS receivers to augment measurement data with accurate time and position.

## Precision Time and Position Context for Measurement Systems 

### *Accurate Sky Referencing in a DIY Radio Telescope*

---

### Lecture overview

* **GPS fundamentals**
  * *How time and position are actually solved*

* **Affordable GNSS hardware**
  * *What you can realistically buy and what it can (and can’t) do*

* **Receiver protocols & data outputs**
  * *How timing and position appear on the wire*

* **Data augmentation considerations**
  * *Turning GNSS into usable context for measurements*

This document explains how low-cost GPS/GNSS receivers can be used to add accurate time and position information to experimental measurement systems.

We start with a high-level look at how GPS works, focusing on the ideas needed to understand timing and positioning accuracy rather than full system details. The goal is to build intuition for where the numbers come from and what limits them.

Next, we look at affordable, off-the-shelf GNSS receivers that are commonly used in hobbyist and research projects. This includes what capabilities they provide, what accuracy is realistic, and what extra features (such as timing outputs) are often overlooked.

We then examine how receivers expose their data, using common text-based formats like NMEA as well as vendor-specific binary protocols. This section focuses on how time and position information appear in practice, not on protocol minutiae.

Finally, we discuss how GNSS data can be used to augment measurements, with attention to error sources, timing alignment, and practical considerations when integrating GPS into real systems.

---

### [[GPS|https://en.wikipedia.org/wiki/Global_Positioning_System]] Overview

**Number of satellites**
: 24

**Height**
: ~20000 km

**Orbit**
: ~12 hour

**Transmission power**
: ~25W (Like a cell phone base station)

**Transmission frequency**
: 1575.42 MHz (L1, civilian)


<p align="center">

![](https://www.gps.gov/sites/default/files/styles/colorbox_style/public/2025-07/GPS-III-A.jpg?itok=X-FlevF2)

*GPS III Satellite from https://www.gps.gov/images*

</p>




The Global Positioning System (GPS) is a satellite-based system that provides precise time and position anywhere on Earth with a clear view of the sky.

The system consists of **at least 24 active satellites** in medium Earth orbit, at an altitude of roughly **20,000 km**. Each satellite completes an orbit about every **12 hours**, ensuring that multiple satellites are visible from any location at most times.

Despite their large distance from Earth, GPS satellites transmit with relatively low power—on the order of **25 W**, comparable to a terrestrial radio transmitter. As a result, GPS signals arrive at the receiver extremely weak and must be recovered from below the noise floor.

For civilian use, GPS satellites transmit primarily on the **L1 frequency at 1575.42 MHz**. All satellites share this same carrier frequency, with individual signals separated using code-division multiple access ([CDMA](https://en.wikipedia.org/wiki/Code-division_multiple_access)).

---

### GPS basics

The [GPS](https://en.wikipedia.org/wiki/Global_Positioning_System) system is based on [trilateration](https://en.wikipedia.org/wiki/Trilateration) to determine the position of a receiver:

$$
c (t-t_i)=\sqrt{(x-x_i)^2+(y-y_i)^2+(z-z_i)^2}\;for\;1 \le i \le N
$$

where:

* $[x_i,y_i,z_i]$ - position of satellite $i$
* $[x,y,z]$ - position of the receiver
* $t_i$  - time of transmission of message from satellite
* $t$ - time of reception to GPS receiver.
* $N$ - number of satellites (seen)

[GPS signals](https://en.wikipedia.org/wiki/GPS_signals) include:

* Time stamps, indicating the satellite transmit time
* Navigation messages containing  [orbital parameters](https://en.wikipedia.org/wiki/Ephemeris), which allow the receiver to compute the satellite’s position at the transmit time

GPS determines position by measuring how long it takes signals from multiple satellites to reach the receiver. Each satellite broadcasts the exact time the signal was sent, along with information that allows the receiver to compute the satellite’s position at that moment.

By multiplying the signal travel time by the speed of light, the receiver gets its distance to each satellite. With enough of these distance measurements, the receiver can determine where it is in space.

In theory, three satellites would be enough if the receiver’s clock were perfectly accurate. In practice, the receiver’s clock is not synchronized with GPS time, so an extra satellite is needed to solve for both position and time at the same time. This is why GPS is fundamentally a timing system as much as it is a positioning system.

---

## One carrier frequency ([[Code-division multiple access|https://en.wikipedia.org/wiki/Code-division_multiple_access]])

- All GPS satellites transmit on the **same carrier frequency**.
- To allow separation of signals, a modulation technique called **{{CDMA+}} (Code Division Multiple Access)** is used.
  - The key idea is that **each satellite is assigned a unique pseudorandom binary sequence ([PRBS](https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence))**.
  - These sequences are designed to be **orthogonal** to one another, meaning they can be separated at the receiver.
  - Orthogonality is illustrated below, where bits are represented as **+1 / −1**.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Cdma_orthogonal_signals.png/250px-Cdma_orthogonal_signals.png"
       alt="Orthogonal CDMA signals">
</p>

- An **information (navigation) signal** is modulated on top of one or a sequence of PRBS by **multiplying with +1 or −1**.
- The resulting signal is then modulated using **{{QPSK+}}**:
  - **Two bits per symbol**.
- The resulting wave is then **mixed** to the L1 frequency.
- At the receiver, the signal is **demodulated using the same sequence** (assuming proper time synchronization)

All GPS satellites transmit on the same radio frequency, so the receiver hears many signals at once. Each satellite uses a unique pseudorandom code that acts like a digital fingerprint.

These codes are uncorrelated with each other, so when the receiver correlates the signal with a given code, signals from other satellites contribute approximately zero. At the same time, each code is perfectly correlated with itself, producing a clear detection when the correct code and timing are used.

Navigation data is carried by flipping the sign of the code, and the result is transmitted using simple phase modulation. By correlating against known codes, the receiver can separate and recover each satellite’s signal even though all satellites share the same carrier frequency.

---
