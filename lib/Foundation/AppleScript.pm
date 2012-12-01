package Foundation::AppleScript;

use strict;
use warnings;

use Foundation;
use Carp;

# ABSTRACT: Perl interface to Cocoa's NSAppleScript class

sub _url_to_nsurl {
    my ($url) = @_;
    my $nsurl = NSURL->alloc->initWithString_($url);
    if ($nsurl and $$nsurl) {
        return $nsurl;
    } else {
        croak "Malformed URL";
    }
}

sub _strdict_to_hash {
    my ($dict) = @_;
    my %hash;
    my $enum = $dict->keyEnumerator;
    for (my $key; # NSString
         ($key = $enum->nextObject) and $$key;
         1)
    {
        my $val = $dict->objectForKey_($key);
        $hash{$key->cString} = ($val && $$val
                                ? $val->cString
                                : undef);
    }
    \%hash;
}

sub _die_with_errordict {
    my ($whence, $dict) = @_;
    if ($dict and $$dict) {
        my $hash = _strdict_to_hash($dict);
        if (%$hash) {
            my @pairs = map { qq[$_: "$hash->{$_}"] } (keys %$hash);
            my $msg = ("$whence: error: {" . (join ", ", @pairs) . "}\n");
            die $msg;
        } else {
            die "$whence: error: {unspecified error}\n";
        }
    } else {
        die "$whence: unspecified error\n";
    }
}

sub new_from_url {
    my ($class, $url) = @_;
    my $errordict;
    my $script = NSAppleScript->alloc->initWithContentsOfURL_error_(
                    _url_to_nsurl($url),
                    my $errordictref = \$errordict);
    if ($script and $$script) {
        my $self = bless { url => $url, nsas => $script }, $class;
        return $self;
    } else {
        _die_with_errordict("new_from_url", $errordict);
    }
}

sub new_from_source {
    my ($class, $source) = @_;
    my $script = NSAppleScript->alloc->initWithSource_($source);
    if ($script and $$script) {
        my $self = bless { source => $source, nsas => $script }, $class;
        return $self;
    } else {
        _die_with_errordict("new_from_source", undef);
    }
}

sub compile {
    my ($self) = @_;
    my $errordict;
    my $worked = $self->{nsas}->compileAndReturnError_(
                                    my $errordictref = \$errordict);
    if ($worked) {
        return $self;
    } else {
        _die_with_errordict("compile", $errordict);
    }
}

sub execute {
    my ($self) = @_;
    my $errordict;
    my $worked = $self->{nsas}->executeAndReturnError_(
                                    my $errordictref = \$errordict);
    if ($worked and $$worked) {
        return $worked;
    } else {
        _die_with_errordict("execute", $errordict);
    }
}

sub is_compiled {
    my ($self) = @_;
    $self->{nsas}->isCompiled;
}

sub source {
    my ($self) = @_;
    my $source_nsstring = $self->{nsas}->source;
    if ($source_nsstring and $$source_nsstring) {
        my $str = $source_nsstring->cString; # XXX unicode?
        return $str;
    } else {
        return undef;
    }
}

1;
__END__
