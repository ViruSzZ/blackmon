package BlackMon;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use feature qw(switch);
# -------------------------------- defaults ------------------------------- #
our $i8kctl     = '/usr/bin/i8kctl';
our $i8k_proc   = '/proc/i8k';
## format of /proc/i8k at the time of writing is:
# 1.0 A11 5YS9JV1 55 -22 1 -22 84000 -1 -22
# |   |   |       |   |  |  |  |      |  |
# |   |   |       |   |  |  |  |      |  +------- 9. buttons status
# |   |   |       |   |  |  |  |      +---------- 8. ac status
# |   |   |       |   |  |  |  +----------------- 7. right fan rpm
# |   |   |       |   |  |  +-------------------- 6. left fan rpm
# |   |   |       |   |  +----------------------- 5. right fan status
# |   |   |       |   +-------------------------- 4. left fan status
# |   |   |       +------------------------------ 3. cpu temperature
# |   |   +-------------------------------------- 2. serial number
# |   +------------------------------------------ 1. bios version
# +---------------------------------------------- 0. /proc/i8k format version
sub new
{
    # sub to act as a reference for
    # calling other methods in the package
    my $class           = shift;
    my %args            = @_;
    my $self            = {};
    $self->{i8kctl}     = $args{i8kctl} || $i8kctl;
    $self->{i8k_proc}   = $args{i8k_proc} || $i8k_proc;
    die("ERROR: $self->{i8k_proc} is not present. did you load i8k? is i8kutils installed?\n\n")
        if(! -e $self->{i8k_proc});
    die("ERROR: $self->{i8kctl} does not exist or is not executable\n\n")
        if(! -e $self->{i8kctl} || ! -x $self->{i8kctl});
    bless( $self, $class );
    return $self;
}
#
sub fetch
{
    ## 1st param as construct to $self
    ## to access parent namespace
    local $self         = shift;
    local %args         = @_;
    local $i8k_proc     = $args{i8k_proc} || $self->{i8k_proc} || $i8k_proc;
    my $Stat = {};
    open(i8k_PROC, "<", $i8k_proc) or die("ERROR: cannot open $i8k_proc for reading: $!\n");
    local $line = <i8k_PROC>; chomp($line); close($file);
    local @i8k_vars = split(/\s+/, $line);
    $Stat->{cpu_temp}       = $i8k_vars[3];
    $Stat->{right_fan_mode} = $i8k_vars[5];
    $Stat->{right_fan_rpm}  = $i8k_vars[7];
    return $Stat;
}
#
sub set
{
    local $self         = shift;
    local %args         = @_;
    local $i8kctl       = $args{i8kctl} || $self->{i8kctl} || $i8kctl;
    given($args{fan_speed})
    {
      when("max") { system("$i8kctl fan - 2 >/dev/null") == 0 or die "system @args failed: $?\n"; }
      when("min") { system("$i8kctl fan - 1 >/dev/null") == 0 or die "system @args failed: $?\n"; }
      when("off") { system("$i8kctl fan - 0 >/dev/null") == 0 or die "system @args failed: $?\n"; }
      default { die("accept 'max', 'min' and 'off' calls only.\n"); }
    }
}
###
1; ## end package / return true
