#!/usr/bin/perl -w
use strict;

use Data::Dumper;
$Data::Dumper::Terse = 0; 

use Gimp;
use Gimp::Feature 'pdl';
#use Gimp::Fu;

my $verbose = 1;
# init Gimp modules
Gimp::set_trace(TRACE_ALL) if $verbose >= 2;
Gimp::init;

my $xcfname = $ARGV[0];
die 'usage: ./exporter.pl foo.xcf' unless $xcfname =~ /\.xcf$/;
my $pmname = $xcfname;
$pmname =~ s/xcf$/pm/;

my $image = Gimp->xcf_load(0, $xcfname, $xcfname);

#$layer = defined $layer ? ($image->get_layers)[$layer] : $image->flatten;
my $visibles_layer = $image->merge_visible_layers(1);#flatten;
my @solid_layers = grep {$_->get_name eq 'solid'} $image->get_layers;
my $solid_layer = $solid_layers[0];
unless ($solid_layer){
   die 'layer named "solid" should not be set to visible.'
}

#now get pixel regions from the important layers
#Something's broken. Forget these regions.
my $solid_region = Gimp->pixel_rgn_init (
   #GimpPixelRgn *pr,
   $solid_layer,
   0,0, $image->width, $image->height,
   0, #dirty
   0 #shadow
);
my $visibles_region = Gimp->pixel_rgn_init (
   #GimpPixelRgn *pr,
   $visibles_layer,
   0,0, $image->width, $image->height,
   0, #dirty
   0 #shadow
);



my @colors;
my %colors; # example: $colors{"141,255,255"} = 0; <==> $colors[0]=[141,255,255];
my @pixels;
my @solid;

sub color_index_of{
   my ($r,$g,$b) = @_;
   my $key = "$r,$g,$b";
   return $colors{$key} if $colors{$key};
   $colors{$key} = [$r,$g,$b];
   return $colors{$key};
}

for my $x (0..$image->width-1){
   print "row $x\n" if $verbose;
   for my $y (0..$image->height-1){
      my ($r,$g,$b,$a) = $visibles_layer->get_pixel ($x,$y);
      $pixels [$y][$x] = color_index_of($r,$g,$b);
      ($r,$g,$b,$a) = $solid_layer->get_pixel ($x,$y);
      $solid [$y][$x] = $a ? 1 : 0;
   }
}


open PMLEVEL, ">$pmname";
print PMLEVEL 'my @colors = ('. join (',',Dumper @colors) . ');';
print PMLEVEL 'my @solid = ('. join (',',Dumper @solid) . ');';
print PMLEVEL 'my @tiles = ('. join (',',Dumper @pixels) . ');';

close PMLEVEL;
