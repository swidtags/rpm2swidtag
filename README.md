# rpm2swidtag

Exploring the rpm header information and producing SWID tag out of it

## Usage

```
usage: rpm2swidtag [-h] [-a | -p] [--regid REGID] [--output-dir DIR]
                   [--authoritative | --evidence-deviceid DEVICE]
                   [--print-tagid]
                   ...

SWID tag parameters.

positional arguments:
  ...                   package(s), glob(s) or file name(s)

optional arguments:
  -h, --help            show this help message and exit
  -a, --all             query all packages with glob pattern
  -p, --package         process rpm package file
  --regid REGID         tag creator's regid
  --output-dir DIR      write SWID tags files into regid subdirectory of DIR;
                        or directly into DIR when the path ends with /.
  --authoritative       produce authoritative tag (per NIST.IR.8060) with
                        Payload, rather than Evidence
  --evidence-deviceid DEVICE
                        Evidence/@deviceId string, defaults to hostname
  --print-tagid         compute and print tagId(s) to standard output
```

## Customizing the output

The SWID tag XML output is produced from template
(`/etc/rpm2swidtag/template.swidtag`) via XSLT stylesheet
(`/etc/rpm2swidtag/rpm2swidtag.xslt`) while injecting values from
the rpm package or rpm file headers.
To customize the output, either edit the default input template and/or
XSLT stylesheet, or point `rpm2swidtag` to alternative locations
for these files, using environment variables `RPM2SWIDTAG_TEMPLATE`
and/or `RPM2SWIDTAG_XSLT`.

The `tagCreator` `Entity` can thus be changed in the input template.
Alternatively, `--regid` option can be used to change the
`tagCreator`'s `@regid` attribute on a command line.

When customizing the XSLT stylesheet,
`{http://adelton.fedorapeople.org/rpm2swidtag}package_tag(tag)`
function can be used to retrieve values from the rpm header for
inclusion in the output SWID tag.

## Printing just `@tagId` values

When the `--print-tagid` option is used, values of `tagId` are
computed and printed to standard output, instead of the full
SWID tag, using stylesheet `/etc/rpm2swidtag/rpm2swidtag-tagid.xslt`.

## SWID tags for all rpms

To generate SWID tags for all packages in the rpm database

```
rpm2swidtag -a --regid $(hostname -f) --output-dir /usr/share
```

can be used. It will produce the `.swidtag` files in
`/usr/share/$(hostname -f)` directory.

## Listing SWID tags

Produced SWID tags can be listed using the `swidq` utility:

```
usage: swidq [-h] [-p] [-a] [-n] [--debug] [-c FILE] [... [... ...]]

List SWID tags.

optional arguments:
  -h, --help            show this help message and exit

selection options:
  -p, --paths           process listed directories and SWID tag files
  -a, --all             match tagId/name with glob pattern, default '*'
  -n, --name            query name instead of tagId

other options:
  --debug               verbose debugging messages
  -c FILE, --config FILE
                        location of the configuration file

remaining arguments:
  ...                   tagId, name, or path
```

By default, config file `/etc/swid/swidq.conf` configures `swidq` to
query directories (or symlinks to directories) under `/etc/swid/swidtags.d`
when looking for SWID tag files.
