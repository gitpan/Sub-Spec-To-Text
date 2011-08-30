package Sub::Spec::To::Text::Usage;

# TODO: use Sub::Spec::To::Org & Org::To::Text

use 5.010;
use strict;
use warnings;

use Sub::Spec::Utils; # tmp, for _parse_schema

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(spec_to_usage);

our $VERSION = '0.02'; # VERSION

our %SPEC;

sub _parse_schema {
    Sub::Spec::Utils::_parse_schema(@_);
}

$SPEC{spec_to_usage} = {
    summary => 'Generate usage text from spec',
    args => {
        spec => ['hash*' => { # XXX spec
            summary => 'The sub spec',
        }],
        command_name => ['str' => {
            summary => 'Name of command',
            description => <<'_',
_
        }],
        options_name => ['str' => {
            summary => 'Name of options',
            description => <<'_',
_
        }],
        is_cmdline => ['bool' => {
            summary => 'Name of options',
            description => <<'_',
_
            default => 0,
        }],
#        lang => ['str' => {
#            summary => 'Language',
#            description => <<'_',
#_
#            in => [qw/en id/],
#            default => 'en',
#        }],
    },
};
sub spec_to_usage {
    # to minimize startup overhead
    require Data::Dump::Partial;
    require List::MoreUtils;

    my %args = @_;
    my $sub_spec = $args{spec} or return [400, "Please specify spec"];
    my $iscmd    = $args{is_cmdline};

    my $usage = "";

    my $cmd = $args{command_name};
    if ($sub_spec->{name}) {
        $cmd = ($sub_spec->{_package} ? "$sub_spec->{_package}::" : "") .
            $sub_spec->{name};
    }
    if ($sub_spec->{summary}) {
        $usage .= ($cmd ? "$cmd - " : "") . "$sub_spec->{summary}\n\n";
    }

    my $desc = $sub_spec->{description};
    if ($desc) {
        $desc =~ s/^\n+//; $desc =~ s/\n+$//;
        $usage .= "$desc\n\n";
    }

    my $args  = $sub_spec->{args} // {};
    my $rargs = $sub_spec->{required_args};
    $args = { map {$_ => _parse_schema($args->{$_})} keys %$args };
    my $has_cat = grep { $_->{clause_sets}[0]{arg_category} }
        values %$args;
    my $prev_cat;
    my $noted_star_req;
    for my $name (sort {
        (($args->{$a}{clause_sets}[0]{arg_category} // "") cmp
             ($args->{$b}{clause_sets}[0]{arg_category} // "")) ||
                 (($args->{$a}{clause_sets}[0]{arg_pos} // 9999) <=>
                      ($args->{$b}{clause_sets}[0]{arg_pos} // 9999)) ||
                          ($a cmp $b) } keys %$args) {
        my $arg = $args->{$name};
        my $ah0 = $arg->{clause_sets}[0];

        my $cat = $ah0->{arg_category} // "";
        if (!defined($prev_cat) || $prev_cat ne $cat) {
            $usage .= "\n" if defined($prev_cat);
            $usage .= ($cat ? ucfirst("$cat options") :
                           ($has_cat ? "General options" :
                                ($args{options_name} ?
                                     "$args{options_name} options" :
                                         "Options")));
            $usage .= " (* denotes required options)"
                unless $noted_star_req++;
            $usage .= ":\n";
            $prev_cat = $cat;
        }

        my $arg_desc = "";

        if ($arg->{type} eq 'any') {
            my @schemas = map {_parse_schema($_)} @{$ah0->{of}};
            my @types   = map {$_->{type}} @schemas;
            @types      = sort List::MoreUtils::uniq(@types);
            $arg_desc  .= "[" . join("|", @types) . "]";
        } else {
            $arg_desc  .= "[" . $arg->{type} . "]";
        }

        my $o = $ah0->{arg_pos};
        my $g = $ah0->{arg_greedy};

        $arg_desc .= " $ah0->{summary}" if $ah0->{summary};
        $arg_desc .= " (one of: ".
            Data::Dump::Partial::dumpp($ah0->{in}).")"
                  if defined($ah0->{in});
        $arg_desc .= " (default: ".
            Data::Dump::Partial::dumpp($ah0->{default}).")"
                  if defined($ah0->{default});

        my $aliases = $ah0->{arg_aliases};
        if ($aliases) {
            $arg_desc .= "\n";
            for (sort keys %$aliases) {
                my $alinfo = $aliases->{$_};
                $arg_desc .= join(
                    "",
                    "      ",
                    (length == 1 ? "-$_" : "--$_"), " ",
                    $alinfo->{summary} ? $alinfo->{summary} :
                        "is alias for '$name'",
                    "\n"
                );
            }
        }

        my $desc = $ah0->{description};
        if ($desc) {
            $desc =~ s/^\n+//; $desc =~ s/\n+$//;
            # XXX format/rewrap
            $desc =~ s/^/      /mg;
            $arg_desc .= "\n$desc\n";
        }

        $usage .= sprintf("  --%-25s %s\n",
                          $name . ($ah0->{required} ? "*" : "") .
                              (defined($o) ? " [or arg ".($o+1).
                                  ($g ? "-last":"")."]" : ""),
                          $arg_desc);
    }

    if ($sub_spec->{cmdline_examples}) {
        $usage .= "\nExamples:\n\n";
        my $cmd = $args{command_name} // $0;
        for my $ex (@{ $sub_spec->{cmdline_examples} }) {
            $usage .= " % $cmd $ex->{cmd}\n";
            my $desc = $ex->{description};
            if ($desc) {
                $desc =~ s/^\n+//; $desc =~ s/\n+$//;
                $usage .= "\n$desc\n\n";
            }
        }
    }

    [200, "OK", $usage];
}

1;
# ABSTRACT: Generate usage/help message from sub spec


=pod

=head1 NAME

Sub::Spec::To::Text::Usage - Generate usage/help message from sub spec

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Sub::Spec::To::Text::Usage qw(spec_to_usage);
 my $text = spec_to_usage(spec=>$spec, ...);

=head1 DESCRIPTION

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

