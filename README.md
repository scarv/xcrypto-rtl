
# [XCrypto](https://github.com/scarv/xcrypto): Hardware Library

*A component part of the
[SCARV](https://github.com/scarv)
project.
This is a library of re-usable hardware components, useful for
implementing the XCrypto ISE.*

---

## Quickstart

- Clone the repository using:
    ```
    $> git clone https://github.com/scarv/xcrypto-rtl.git
    $> cd xcrypto-rtl
    ```
- Setup the project environment:
    ```
    $> source bin/conf.sh
    ```

- Synthesise all of the RTL modules:
    ```
    $> make synth-all
    ```
  The results will appear in `build/<module name>/`


- Run BMC proofs of correctness on the modules:
    ```
    $> make bmc-all
    ```

- Run all checks and synthesis jobs for a particular module:
    ```
    $> make <module name>
    ```

## Modules implented

This is a list of the modules in the repository and a rough
estimate of their gate count, as per an example Yosys CMOS flow.

Module Name     | Instructions Implemented  | Yosys CMOS Gate Count
----------------|---------------------------|------------------------------
`b_bop`         | `xc.bop`                  | 737
`b_lut`         | `xc.lut`                  | 1280
`p_addsub`      | `xc.padd`,`xc.psub`       | 617
`p_shfrot`      | `xc.psrl[.i]`,`xc.psll[.i]`,`xc.prot[.i]` | 1244
`xc_sha3`       | `xc.sha3.[xy,x1,x2,x4,yx]` | 446

---

## Acknowledgements

This work has been supported in part by EPSRC via grant 
[EP/R012288/1](https://gow.epsrc.ukri.org/NGBOViewGrant.aspx?GrantRef=EP/R012288/1),
under the [RISE](http://www.ukrise.org) programme.

