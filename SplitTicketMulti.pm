# --
# Kernel/System/ProcessManagement/TransitionAction/SplitTicketMulti.pm - to create multiple splited 
# tickets from within a process
# Copyright (C) 2001-2013 Nomadic Solutions, http://gridshield.net/
# --
# $Id: SplitTicketMulti.pm,v 1.00 2013/04/01 11:27:42 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

# wrapper for split ticket, to run multiple splits

package Kernel::System::ProcessManagement::TransitionAction::SplitTicketMulti;

use utf8;
use Kernel::System::ProcessManagement::TransitionAction::SplitTicket;
use Data::Dumper;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.0 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (
    	qw(TicketObject LogObject)
        )
    {
	if (!$Param{$Needed})  {
		 $Self->{LogObject}->Log(
                	Priority => 'error',
			Message => "Got no $Needed!");
	        die "Got no $Needed!";
	}
        $Self->{$Needed} = $Param{$Needed};
    }
	
	$Self->{SplitTicket} = new Kernel::System::ProcessManagement::TransitionAction::SplitTicket(%Param);

	return $Self;
	}

sub Run {
    my ( $Self, %Param ) = @_;

	my @MultiKeys=(qw (CheckField title Queue process activity fields));
	my %multiParams;

    for my $Needed (qw(UserID Ticket Config )) {
        if ( !defined $Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

	foreach my $key (keys(%{$Param{Config}})) {
		foreach my $multikey (@MultiKeys) {
			if ($key =~ /$multikey\[(\d*)\]/) {
				$multiParams{$1}->{$multikey} = $Param{Config}->{$key};
			}
		}
			
	}


	foreach my $multiParam (values(%multiParams)) {
		next unless ($Param{Ticket}->{"DynamicField_".$multiParam->{CheckField}} == 1);
		my %tmpConfig = (%{$Param{Config}}, %{$multiParam});
		my %tmpParams = %Param;
		$tmpParams{Config}=\%tmpConfig;

		$Self->{SplitTicket}->Run(%tmpParams);
	}

}
1;
