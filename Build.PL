
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Generate text documentation from spec",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Sub-Spec-To-Text",
  "dist_version" => "0.05",
  "license" => "perl",
  "module_name" => "Sub::Spec::To::Text",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dump::Partial" => 0,
    "Data::Sah" => "0.02",
    "Sub::Spec" => "0.14",
    "Test::More" => "0.96",
    "perl" => "5.010000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
