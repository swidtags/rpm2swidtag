# rpm2swidtag

Exploring the rpm header information and producing SWID tag out of it

## Usage

```
usage: rpm2swidtag [-h] [-a | -p] [--regid REGID] [--output-dir OUTPUT_DIR]
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
  --output-dir OUTPUT_DIR
                        write SWID tags to files under regid subdirectory of
                        this directory
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
