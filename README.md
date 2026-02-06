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

### [GPS](https://en.wikipedia.org/wiki/Global_Positioning_System) Overview

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

### One carrier frequency ([Code-division multiple access](https://en.wikipedia.org/wiki/Code-division_multiple_access))

- All GPS satellites transmit on the **same carrier frequency**.
- To allow separation of signals, a modulation technique called **[Code-division multiple access](https://en.wikipedia.org/wiki/Code-division_multiple_access)** is used.
  - The key idea is that **each satellite is assigned a unique pseudorandom binary sequence ([PRBS](https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence))**.
  - These sequences are designed to be **orthogonal** to one another, meaning they can be separated at the receiver.
  - Orthogonality is illustrated below, where bits are represented as **+1 / −1**.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Cdma_orthogonal_signals.png/250px-Cdma_orthogonal_signals.png"
       alt="Orthogonal CDMA signals">
</p>

- An **information (navigation) signal** is modulated on top of one or a sequence of PRBS by **multiplying with +1 or −1**.
- The resulting signal is then modulated using **[Quadrature phase shift keying](https://en.wikipedia.org/wiki/Phase-shift_keying#Quadrature_phase-shift_keying_(QPSK))**:
  - **Two bits per symbol**.
- The resulting wave is then **mixed** to the L1 frequency.
- At the receiver, the signal is **demodulated using the same sequence** (assuming proper time synchronization)

All GPS satellites transmit on the same radio frequency, so the receiver hears many signals at once. Each satellite uses a unique pseudorandom code that acts like a digital fingerprint.

These codes are uncorrelated with each other, so when the receiver correlates the signal with a given code, signals from other satellites contribute approximately zero. At the same time, each code is perfectly correlated with itself, producing a clear detection when the correct code and timing are used.

Navigation data is carried by flipping the sign of the code, and the result is transmitted using simple phase modulation. By correlating against known codes, the receiver can separate and recover each satellite’s signal even though all satellites share the same carrier frequency.

---

### Quadrature modulation and QPSK

* GPS signals are represented as a **complex baseband signal**

  * **In-phase (I)** component
  * **Quadrature (Q)** component
* The PRN code and navigation data take values **±1**
* These values **multiply cosine and sine carriers**
* Changing the sign corresponds to a **180° phase shift**
* Combining I and Q sign changes produces **four phase states**

  * **Two bits per symbol ([QPSK](https://en.wikipedia.org/wiki/Phase-shift_keying#Quadrature_phase-shift_keying_(QPSK)))**
* The resulting signal is **mixed up to the L1 carrier frequency**
* At the receiver, the signal is **mixed down** and processed in baseband


<p align="center">

![](https://upload.wikimedia.org/wikipedia/commons/8/8f/QPSK_Gray_Coded.svg)

*Constellation diagram for QPSK*

</p>

$$
s(t) = I_k \cos(\omega t) - Q_k \sin(\omega t),
\quad I_k, Q_k \in {\pm 1}
$$

Quadrature modulation maps a complex baseband signal onto a real radio waveform by placing the in-phase and quadrature components on cosine and sine carriers that are 90° apart. In [QPSK](https://en.wikipedia.org/wiki/Phase-shift_keying#Quadrature_phase-shift_keying_(QPSK)), the PRN code and navigation data simply flip the signs of these carriers. A sign flip does not change amplitude—it shifts the carrier phase by 180°. Different combinations of sign flips produce the four constellation points shown above. This makes QPSK a natural extension of PRN code modulation and explains why phase modulation and sign changes are equivalent ways of describing the same signal.

---

### [Delay locked loop](https://gssc.esa.int/navipedia/index.php/Delay_Lock_Loop_%28DLL%29)

* **What this is (DLL)**: A Delay Lock Loop (DLL) aligns a locally generated PRN code with a GNSS signal that arrives **well below the noise floor**, enabling precise satellite ranging.
* **Correlation peak in noise**: By correlating the received signal with a local replica of the same PRN (effectively a form of **auto-correlation**), a sharp correlation peak emerges when timing is correct, even though the signal is buried in noise.
* **Closed-loop timing control**: Early/Prompt/Late correlations form a DLL that iteratively shifts the local PRN timing until the correlation peak is centered.
* **Code vs. data timing**: The PRN code itself does not represent a navigation bit; navigation data modulates many repetitions of the PRN.
* **GPS L1 C/A example & scale**: A 1 ms PRN (1023 chips at 1.023 Mcps) repeats **20 times** during one 20 ms navigation data bit (50 bps); a **1 ns timing error corresponds to ~30 cm** of range error at the speed of light.

A delay locked loop is how a GPS receiver lines up its locally generated code with the extremely weak signal coming from a satellite. Even though the signal arrives well below the noise floor, correlating it with the correct code reveals a clear timing peak when alignment is right.

The receiver continuously adjusts the timing of its local code by comparing slightly early, on-time, and slightly late versions. This feedback loop keeps the correlation peak centered and allows the receiver to track the signal’s arrival time very precisely.

It is important to distinguish between code timing and navigation data. The pseudorandom code repeats many times and is used purely for timing and ranging, while the navigation data changes much more slowly and is carried on top of the code. Small timing errors at the code level translate directly into position errors, which is why accurate code tracking is critical for both positioning and precise time output.

---

### [Kalman filter](https://en.wikipedia.org/wiki/Kalman_filter)

* **A kind of Bayesian filter**: it repeatedly **predicts** the system state and then **updates** that belief with new measurements, progressively increasing precision over time.

* **Prediction + correction loop**: combines a **system model** with noisy measurements, weighting each by their uncertainty.

* **Interesting facts**:

  * The equations are derived assuming **Gaussian distributions** (linear dynamics, Gaussian noise), but the filter is **surprisingly robust in practice** even when assumptions are imperfect.
  * It explicitly integrates a **system model** (e.g., position and velocity in GPS), which allows it to **estimate hidden or unmeasured states**, similar in spirit to a **Markov process**.


<p align="center">

![](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Basic_concept_of_Kalman_filtering.svg/960px-Basic_concept_of_Kalman_filtering.svg.png)

*Basic concept of Kalman filtering, from Wikipedia*

</p>

A minimal Kalman filter example in Julia is available [here](https://github.com/anbjos/GNSS-augmentation/blob/main/kalman.jl)

A Kalman filter is a practical way to get a cleaner estimate from noisy data over time. It works in a loop: first it predicts what the next state should be using a simple model (for example, “position and velocity evolve smoothly”), and then it corrects that prediction using the latest measurement.

The key idea is weighting: if the measurements are noisy, the filter trusts the model a bit more; if the model is uncertain, it trusts the measurements more. This makes it especially useful in GNSS, where you want stable estimates of position, velocity, and clock behavior even when individual measurements jump around.

Although the standard equations assume linear dynamics and Gaussian noise, Kalman filters tend to work well in practice even when reality is messier. Because the filter carries a model of the system, it can also estimate quantities that are not directly measured (for example, velocity or clock drift) from the measurements it does have.

---

### GPS error sources and advanced processing

#### Advanced processing

* **Doppler effects**
  Relative motion between satellites and receiver
* **Relativistic effects**
  Predictable time offsets due to speed and gravity
* **Satellite constellation effects**

  * **Assisted GPS** provides time, orbit data, and coarse position
    → faster, more reliable lock
  * **Without assistance**, navigation data must be decoded from satellites
    → slower lock, more sensitive to weak signals

#### Error sources

* **[Ionosphere](https://en.wikipedia.org/wiki/Ionosphere) effects**
  Frequency-dependent propagation delay
  → mitigated using **RTK** or dual-frequency methods
* **[Multipath propagation](https://en.wikipedia.org/wiki/Multipath_propagation) propagation**
  Signal reflections in the local environment
  → satellites high in the sky are less affected
  → known position can enable precise timing from a single satellite

Advanced processing corrects predictable effects and improves acquisition, while error sources distort the signal during propagation. Assisted GPS mainly reduces time-to-lock by providing prior information, whereas standalone receivers must learn this from the satellites themselves. For timing applications, prior knowledge and environment often matter more than raw signal strength.

---

### [ArduSimple simpleGNSS Timing](https://www.ardusimple.com/product/simplegnss-timing/)

* Low-cost GNSS timing board suitable for **measurement data augmentation**

<p align="center">

![Board](https://www.unmannedsystemstechnology.com/wp-content/uploads/2024/08/simpleGNSS-Timing-235x235.jpg)

*[ArduSimple simpleGNSS Timing](https://www.ardusimple.com/wp-admin/admin-post.php?action=generate_product_pdf&product_id=54779)*

</p>

* Provides **absolute time and position** using GNSS
* Is affordable
* Primary interfaces:

  * **UART** for GNSS data (NMEA / UBX)
  * **Timepulse (sync pulse / PPS)** output
* PPS is aligned to **GPS / UTC time**

  * Used to **timestamp measurements**
  * Used to **synchronize acquisition systems**
* The timepulse output is **configurable**

  * Can be used as a **clock reference**
  * Using it as a clock requires **additional handling** to recover exact time

The simpleGNSS Timing board offers an accessible way to add accurate time and position information to experimental setups such as a DIY radio telescope. GNSS data is available over UART, while the timepulse output provides a precise synchronization signal aligned to UTC. In this work, the sync pulse is used as the primary timing reference for timestamping measurement data. Although the same output can be configured to provide a clock reference, doing so requires extra logic to relate the clock phase back to absolute time, which is beyond the basic use case presented here.

---

### [u-blox NEO-F10N GNSS module](https://content.u-blox.com/sites/default/files/documents/NEO-F10N_DataSheet_UBX-23002117.pdf)


* Multi-band GNSS receiver used on the **ArduSimple timing board**
* Provides:

  * **Position and absolute time over UART** (NMEA / UBX)
  * **Configurable sync pulse (PPS)** aligned to GNSS time
* Internal operation:

  * Absolute time is solved **continuously** in the receiver
  * The PPS edge is generated from a **discrete internal clock**
  * This introduces a small **quantization error** in the sync pulse
  * **Sync accuracy is therefore largely limited by this quantization**
* For a DIY radio telescope:

  * **PPS enables precise timestamping of measurements**
  * **UART provides absolute time and coarse position**

<p align="center">

![picture](https://content.u-blox.com/sites/default/files/styles/740_width/public/2023-09/NEO-F10N-top-bottom.png)

*NEO-F10N*

</p>


The NEO-F10N is the GNSS timing and positioning module at the core of the simpleGNSS Timing board. For a DIY radio telescope, its primary value is the **sync pulse aligned to GNSS time**, which allows accurate timestamping of measurement data. Because the electrical PPS must be generated from an internal clock, a small quantization error remains and dominates the residual sync uncertainty. The receiver exposes timing information over UART—discussed in a later section—enabling precise interpretation of the sync signal within practical measurement systems.

---

### [NMEA 0183](https://en.wikipedia.org/wiki/NMEA_0183)

* Standard **text-based GNSS output**
* Sent as **[ASCII](https://en.wikipedia.org/wiki/ASCII) over [UART](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter)**, easy to read and parse
* Sentences contain:

  * **UTC time and date**
  * **Latitude and longitude**
  * **Motion and fix status**
* Example: **GNRMC (Recommended Minimum data)**
* Useful for **basic timestamping and logging**
* **Not timing-precise** → detailed timing is in **binary protocols** (next section)

```
$GNRMC,               ← Talker ID: GN = multi-GNSS, RMC = Recommended Minimum
120305.00,            ← UTC time: 12:03:05.00 (hhmmss.ss)
A,                    ← Status: A = valid fix (V = invalid)
3746.1234,N,          ← Latitude: 37°46.1234' North
12225.6789,W,         ← Longitude: 122°25.6789' West
0.01,                 ← Speed over ground (knots)
123.4,                ← Course over ground (degrees)
280126,               ← Date: 28 Jan 2026 (ddmmyy)
,,                    ← Magnetic variation (often empty)
A                     ← Mode indicator (A = autonomous GNSS)
*6C                   ← Checksum
```

NMEA 0183 provides simple, human-readable GNSS time and position over UART, suitable for logging and basic synchronization. Precise timing and receiver status require the **binary GNSS protocol**, discussed next.

---

### [u-blox UBX protocol](https://wiki.openstreetmap.org/wiki/U-blox_raw_format)

* **Binary GNSS data format** used by u-blox receivers

  * More compact and structured than NMEA
  * Still **simple to parse** with fixed message layouts
* Provides detailed receiver information:

  * **Precise time and status**
  * **Navigation solution and configuration**
* Timing-related messages are **aligned with the sync pulse (PPS)**

  * Include **quantization error** and timing uncertainty for each pulse
  * Enable **precise timestamp reconstruction** in software
* Practical use:

  * Read messages over **UART**
  * Decode using published **u-blox protocol documentation**
  * Commonly handled with small scripts or embedded code
* Reference:

  * *u-blox Interface Description / UBX protocol specification*

The UBX protocol exposes the internal timing and navigation state of the receiver in a compact binary form that is straightforward to decode programmatically. Unlike NMEA, it provides timing information synchronized to each PPS event, including the reported quantization error of the electrical pulse relative to true GNSS time. This makes UBX the key interface for achieving precise, reproducible timestamps in measurement systems such as a DIY radio telescope.

---

### Increasing precission of syncsignal

Quantization errors due to reclocking on ardu simple and DIY radio telescope.

---

### References

* [u-blox timing application note](https://content.u-blox.com/sites/default/files/products/documents/Timing_AppNote_%28GPS.G6-X-11007%29.pdf)
* [Wikipedia Kalman filter](https://en.wikipedia.org/wiki/Kalman_filter)
* [Wikipedia Code division multiple access](https://en.wikipedia.org/wiki/Code-division_multiple_access)
* [RFWirelessWorld cdma-tutorial-basics](https://www.rfwireless-world.com/tutorials/cdma-tutorial-basics-walsh-pn-sequence-phy-layer)


---
