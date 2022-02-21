# Bash-dhcp-starvation

Simple DHCP Starvation attack with bash.

## Fast start

This project requires the `macchanger` package that you can install with `sudo apt install macchanger`

Run `cd Bash-dhcp-starvation && chmod u+x dhcp-starvation.sh && sudo ./dhcp-starvation.sh` and the attack will start.

If you get the next output:

```bash
down: error fetching interface information: Device not found
GNU MAC Changer Usage: macchanger [options] device Try `macchanger --help' for more options.
up: error fetching interface information: Device not found
```

Then you have to run the script and tell what interface you want to run the attack with. I.E: `./dhcp-starvation.sh enp0s3`
