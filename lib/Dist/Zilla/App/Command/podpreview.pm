package Dist::Zilla::App::Command::podpreview;

# ABSTRACT: preview munged pod in browser

use strict;
use warnings;
use 5.010;
use Dist::Zilla::App -command;
use Moose::Autobox;
use App::PodPreview qw(podpreview);
use List::Util      qw(first);
use File::Temp      qw(tempfile);
use Carp            qw(carp croak);

sub abstract { "preview munged pod in browser" }

sub usage_desc { "dzil podpreview My::Module" }

sub validate_args
{
    my ($self, $opt, $arg) = @_;

    my ($first, @extra) = @$arg;

    $self->usage_error("please specify what you want to preview") unless $first;

    carp( "podpreview accepts a single argument, ignoring " . join ',', @extra )
        if @extra;
}

sub execute
{
    my ($self, $opt, $arg) = @_;

    $self->app->chrome->logger->mute;

    $_->before_build for $self->zilla->plugins_with(-BeforeBuild)->flatten;
    $_->gather_files for $self->zilla->plugins_with(-FileGatherer)->flatten;
    $_->prune_files  for $self->zilla->plugins_with(-FilePruner)->flatten;
    $_->munge_files  for $self->zilla->plugins_with(-FileMunger)->flatten;

    my $module = $arg->[0];
    my $colons = $module =~ s/::/\//g;
    my @filenames = "lib/$module.pm";
    push @filenames, "bin/$module", $module if !$colons;

    my $object = first { $_->name ~~ @filenames } @{ $self->zilla->files };
    croak "Cannot find object " . $arg->[0] unless $object;

    my ($fh, $filename) = tempfile();
    print $fh $object->content or croak $!;
    close $fh or corak $!;
    podpreview($filename);
}

1;

=pod

=head1 SYNOPSIS

    dzil podpreview My::Module

=head1 DESCRIPTION

A L<Dist::Zilla> command to preview the munged pod of a module in a browser using L<App::PodPreview>.

=head1 SEE ALSO

=for: list
* L<Dist::Zilla>
* L<App::PodPreview>

