# --
# Kernel/System::ProcessManagement::TransitionAction::MergeTicket.pm - to merge tickets from a Process
# Copyright (C) 2013 Nomadic Solutions , http://gridshield.net/
# --
# $Id: MergeTicket.pm,v 1.00 2013/04/001 11:27:42 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::MergeTicket;

use Kernel::System::SystemAddress;
use Kernel::System::CustomerUser;
use Kernel::System::CheckItem;
use Kernel::System::Web::UploadCache;
use Kernel::System::State;
use Kernel::System::LinkObject;
use Kernel::System::DynamicField;
use Kernel::System::DynamicField::Backend;
use Kernel::System::VariableCheck qw(:all);
use Mail::Address;
# ---
# ITSM
# ---
use Kernel::System::Service;
use Kernel::System::GeneralCatalog;
use Kernel::System::ITSMCIPAllocate;
# ---
use utf8;
use Data::Dumper;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.3 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (
        qw(ParamObject DBObject TicketObject LayoutObject LogObject QueueObject MainObject ConfigObject)
        #qw(ConfigObject LogObject EncodeObject DBObject MainObject TimeObject TicketObject)
        )
    {
   #    die "Got no $Needed!" if !$Param{$Needed};
        $Self->{$Needed} = $Param{$Needed};
    }


	$Self->{LinkObject}         = Kernel::System::LinkObject->new(%Param);
	$Self->{DynamicFieldObject} = Kernel::System::DynamicField->new(%Param);
    $Self->{BackendObject}      = Kernel::System::DynamicField::Backend->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    for my $Needed (qw(UserID Ticket Config )) {
        if ( !defined $Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "MergeTicket.pm  Need $Needed!",
            );
            return;
        }
    }

    # Check if we have Ticket to deal with
    if ( !IsHashRefWithData( $Param{Ticket} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "MergeTicket.pm Ticket has no values!",
        );
        return;
    }

    # Check if we have a ConfigHash
    if ( !IsHashRefWithData( $Param{Config} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "MergeTicket.pm Config has no values!",
        );
        return;
    }
    
	#find the ticket parent
	my %ticketsParent = $Self->{LinkObject}->LinkKeyListWithData(
        Object1   => 'Ticket',
        Key1      => $Param{Ticket}->{TicketID},
        Object2   => 'Ticket',
        State     => 'Valid',
        Type      => 'ParentChild', # (optional)
        Direction => 'Source',      # (optional) default Both (Source|Target|Both)
        UserID    => 1,
       );

    my $parentTicketId = 1;
   
   foreach $key (keys %ticketsParent){
   	$parentTicketId = $key;
   }
   
   if($Param{Config}->{fields}){
		#get the dynamic Field 
		my %parentTicketSearch = $Self->{TicketObject}->TicketGet(
			TicketID      => $parentTicketId,
			DynamicFields => 1,         # Optional, default 0. To include the dynamic field values for this ticket on the return structure.
			UserID        => 1,
			Silent        => 0,         # Optional, default 0. To suppress the warning if the ticket does not exist.
		);

		my %childTicketSearch = $Self->{TicketObject}->TicketGet(
                        TicketID      => $Param{Ticket}->{TicketID},
                        DynamicFields => 1,         # Optional, default 0. To include the dynamic field values for this ticket on the return structure.
                        UserID        => 1,
                        Silent        => 0,         # Optional, default 0. To suppress the warning if the ticket does not exist.
                );
		
	
		my @ticketDynamicFields = split(',', $Param{Config}->{fields});
		
		foreach my $field (@ticketDynamiFields) {
			if ($parentTicketSearch{"DynamicField_".$field}){
				# get config for ProcessManagementActivityID dynamic field
				my $fieldConfig = $Self->{DynamicFieldObject}->DynamicFieldGet(
					Name => $field,
				);
				my $fieldSuccess = $Self->{BackendObject}->ValueSet(
					DynamicFieldConfig => $fieldConfig,
					ObjectID	=> $parentTicketId,
					Value           => $childTicketSearch{"DynamicField_".$field},
					UserID           => 1,
				); 
				if (!$fieldSuccess){
					#something wrong
					$Self->{LogObject}->Log(
						Priority => 'error',
						Message  => "MergeTicket.pm Cannot set  DynamicField (".$field.") value to parent ticket :".$parentTicketId." , child ticket: ".$Param{Ticket}->{TicketID},
					);
				}else{
					$Self->{LogObject}->Log(
                           			 Priority => 'info',
                            			Message  => "MergeTicket.pm  DynamicField (".$field.")  changed to: ".$childTicketSearch{"DynamicField_".$field}."\n child ticket :".$Param{Ticket}->{TicketID}.", parent ticket:".$parentTicketId,
                        		);
				}
				
			}else{
				$Self->{LogObject}->Log(
					Priority => 'error',
					Message  => "MergeTicket.pm Cannot add DynamicField (".$field.") to parent ticket :".$parentTicketId." the child ticket: ".$Param{Ticket}->{TicketID}." doesn't have DynamicField: ".$field,
				);     
			}
		}
		
    };
     

	# merge the child within the parent
	$Self->{TicketObject}->TicketMerge(
                MainTicketID  => $parentTicketId,
                MergeTicketID => $Param{Ticket}->{TicketID},
                UserID        => 1,
            );

        
	$Self->{LogObject}->Log(
            Priority => 'info',
            Message  => "MergeTicket.pm called with Merge Ticket: ".$Param{Ticket}->{TicketID} . " Main Ticket: ".$parentTicketId ,
        );
	
    return ;
}
1;
