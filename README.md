# rpm2swidtag, rpm2swidtag DNF plugin, and swidq

Tools for producing SWID tags for rpm packages and inspecting the SWID tags.

## Producing SWID tags for rpm packages

Utility `rpm2swidtag` creates SWID tags for rpm packages, installed in
rpm database or rpm files:

```
usage: rpm2swidtag [-h] [-a | -p | --repo DIR]
                   [--tag-creator SOURCE-FILE, REGID or "REGID NAME"]
                   [--software-creator SOURCE-FILE, REGID or "REGID NAME"]
                   [--sign-pem KEYFILE.pem[,CA.pem[...]]] [--output-dir DIR]
                   [--authoritative | --evidence-deviceid DEVICE]
                   [--primary-only] [--print-tagid]
                   [--preserve-signing-template] [--config FILE]
                   [... [... ...]]

Generating SWID tags for rpm packages.

positional arguments:
  ...                   package(s), glob(s) or file name(s)

optional arguments:
  -h, --help            show this help message and exit
  -a, --all             query all packages with glob pattern
  -p, --package         process rpm package file
  --repo DIR            create SWID tag information for yum/dnf repo
  --tag-creator SOURCE-FILE, REGID or "REGID NAME"
                        tagCreator Entity attributes
  --software-creator SOURCE-FILE, REGID or "REGID NAME"
                        softwareCreator Entity attributes
  --sign-pem KEYFILE.pem[,CA.pem[...]]
                        PEM files with key and certificates
  --output-dir DIR      write SWID tags files into regid subdirectory of DIR;
                        or directly into DIR when the path ends with /.
  --authoritative       produce authoritative tag (per NIST.IR.8060) with
                        Payload, rather than Evidence
  --evidence-deviceid DEVICE
                        Evidence/@deviceId string, defaults to hostname
  --primary-only        do not generate supplemental tags
  --print-tagid         compute and print tagId(s) to standard output
  --preserve-signing-template
                        keep the XML signing template in the output (for
                        subsequent signing)

config options:
  --config FILE         location of the configuration file
```

### Customizing the output

The SWID tag XML output is produced from template
(`/etc/rpm2swidtag/template.swidtag`) via XSLT stylesheet
(`/etc/rpm2swidtag/rpm2swidtag.xslt`) while injecting values from
the rpm package or rpm file headers.
To customize the output, either edit the default input template and/or
XSLT stylesheet, or point `rpm2swidtag` to alternative locations
for these files, using environment variables `RPM2SWIDTAG_TEMPLATE`
and/or `RPM2SWIDTAG_XSLT`.

The `tagCreator` `Entity` can thus be changed in the input template.
Alternatively, `--tag-creator` option can be used to change the
`tagCreator`'s `@regid` and `@name` attributes on a command line.

When customizing the XSLT stylesheet,
`{http://adelton.fedorapeople.org/rpm2swidtag}package_tag(tag)`
function can be used to retrieve values from the rpm header for
inclusion in the output SWID tag.

### Printing just `@tagId` values

When the `--print-tagid` option is used, values of `tagId` are
computed and printed to standard output, instead of the full
SWID tag, using stylesheet `/etc/rpm2swidtag/rpm2swidtag-tagid.xslt`.

### SWID tags for all rpms

To generate SWID tags for all packages in the rpm database

```
rpm2swidtag -a --tag-creator $(hostname -f) --output-dir /usr/lib/swidtag
```

can be used. It will produce the `.swidtag` files in
`/usr/lib/swidtag/$(hostname -f)` directory.

### SWID tags for yum/dnf repository

Running `rpm2swidtag` with `--repo` option will produce SWID tags
for yum/dnf repository and put them into single XML file which
is then referenced from repository's top-level `repomd.xml` metadata
file with type `swidtags`.

## Listing SWID tags

Produced SWID tags can be listed using the `swidq` utility:

```
usage: swidq [-h] [-p] [-a] [-n] [--rpm] [-i] [-l] [--dump] [--xml]
             [--output-stylesheet FILE] [--debug] [--silent] [-c FILE]
             [... [... ...]]

Querying SWID tags.

optional arguments:
  -h, --help            show this help message and exit

selection options:
  -p, --paths           process listed directories and SWID tag files
  -a, --all             match tagId/name with glob pattern, default '*'
  -n, --name            query name instead of tagId
  --rpm                 query rpm Resource instead of tagId

output options:
  -i, --info            output some SWID tag fields
  -l, --list-files      list files from the SWID tag
  --dump                dump SWID tag content as indented text
  --xml                 output SWID tags as XML
  --output-stylesheet FILE
                        output via custom XSLT stylesheet

other options:
  --debug               verbose debugging messages
  --silent              suppress non-fatal warnings
  -c FILE, --config FILE
                        location of the configuration file

remaining arguments:
  ...                   tagId, name, or path
```

By default, config file `/etc/swid/swidq.conf` configures `swidq` to
query directories (or symlinks to directories) under `/etc/swid/swidtags.d`
when looking for SWID tag files.

## Keeping SWID tags in sync with installed rpm packages

DNF plugin `rpm2widtag` can be used to create SWID tags for newly
installed packages and remove SWID tags for packages removed,
automatically, after DNF transaction finishes.

```
usage: dnf rpm2swidtag {enable,enable-regen,disable,disable-purge}

Generate SWID tag files for installed rpms

positional arguments:
    enable              enable rpm2swidtag plugin
    enable-regen        enable + generate SWID tags for already installed rpms
    disable             disable rpm2swidtag plugin
    disable-purge       disable + remove all tags generated by rpm2swidtag
                        plugin
```

The `dnf rpm2swidtag enable` enables the DNF plugin by creating symlink
`/etc/swid/swidtags.d/rpm2swidtag-generated`, pointing to
`/var/lib/swidtag/rpm2swidtag-generated`. Any DNF operation which
adds (or removes or updates) packages then results in needed SWID tags
being placed into (or removed from)
`/var/lib/swidtag/rpm2swidtag-generated`.

When the dnf repository includes collection of SWID tags for its packages,
these SWID tags will be stored to local disk under
`/var/lig/swidtag/<tagCreator>` rather than locally generated.

## Author

Written by Jan Pazdziora, 2018--2019.

## License

Copyright 2018--2019, Red Hat, Inc.

Licensed under the Apache License, Version 2.0.
