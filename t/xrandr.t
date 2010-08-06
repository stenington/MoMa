use strict;
use warnings;

use Test::More 'no_plan';
use App::Moma;

ok( `xrandr`, "we can call xrandr");

# check config
{
  my $app = App::Moma->new();
  my $query =<<END;
Screen 0: minimum 320 x 200, current 2560 x 1024, maximum 2560 x 1024
LVDS connected (normal left inverted right x axis y axis)
   1280x800       60.0  
   1280x768       60.0  
   1024x768       60.0  
   800x600        60.3  
   640x480        60.0     59.9  
DVI-0 connected 1280x1024+1280+0 (normal left inverted right x axis y axis) 376mm x 301mm
   1280x1024      60.0*+   75.0     59.9  
   1152x864       74.8  
   1024x768       75.1     60.0  
END
  my $avail = $app->_parse_available( $query );
  is_deeply( [sort keys %$avail], ["DVI-0", "LVDS"], "available ports found" );
  is_deeply( [sort keys %{$avail->{"DVI-0"}}], ["1024x768", "1152x864", "1280x1024"], "modes found" );
  $app->load_rc( "t/.moma" );
  my $report = $app->_check_config( $avail );
  like( $report, qr/VGA-0 not connected/, "reports VGA-0 not connected" );
  like( $report, qr/1280x1024 not available for LVDS/, "reports unavailable mode" );
  like( $report, qr/available modes are/, "reports available alternative modes" );

  $query =<<END;
Screen 0: minimum 320 x 200, current 2560 x 1024, maximum 2560 x 1024
LVDS connected (normal left inverted right x axis y axis)
   1280x1024      60.0
   1280x800       60.0  
   1280x768       60.0  
   1024x768       60.0  
   800x600        60.3  
   640x480        60.0     59.9  
DVI-0 connected 1280x1024+1280+0 (normal left inverted right x axis y axis) 376mm x 301mm
   1280x1024      60.0*+   75.0     59.9  
   1152x864       74.8  
   1024x768       75.1     60.0  
VGA-0 connected 1280x1024+1280+0 (normal left inverted right x axis y axis) 376mm x 301mm
   1280x1024      60.0*+   75.0     59.9  
   1152x864       74.8  
   1024x768       75.1     60.0  
END
  $avail = $app->_parse_available( $query );
  $app->load_rc( "t/.moma" );
  $report = $app->_check_config( $avail );
  like( $report, qr/Looks good!/, "looks good message when no problems found" );
}
