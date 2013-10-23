# --
# Kernel/System/ProcessManagement/TransitionAction/SplitTicket.pm - to split tickets from within a process
# Copyright (C) 2001-2013 Nomadic Solutions, http://gridshield.net/
# -- alvaro@gridshield.net
# $Id: SplitTicket.pm,v 1.00 2013/04/01 11:27:42 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::SplitTicket;


use Kernel::System::LinkObject;
use Kernel::System::DynamicField;
use Kernel::System::DynamicField::Backend;
use Kernel::System::VariableCheck qw(:all);
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
    	qw(ParamObject TicketObject LogObject)
        #qw(ParamObject DBObject TicketObject LayoutObject LogObject QueueObject MainObject ConfigObject)
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
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Check if we have Ticket to deal with
    if ( !IsHashRefWithData( $Param{Ticket} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Ticket has no values!",
        );
        return;
    }

    # Check if we have a ConfigHash
    if ( !IsHashRefWithData( $Param{Config} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Config has no values!",
        );
        return;
    }
	
   
   
    
        
    #my $CustomerID = $Self->{ParamObject}->GetParam( Param => 'CustomerID' ) ;    
    # create new ticket, do db insert
    my $newTicketID = $Self->{TicketObject}->TicketCreate(
            Title         => $Param{Config}->{title},
   			Queue         => $Param{Config}->{Queue}, # or QueueID => 123,
   			Lock          => 'unlock',
   			Priority      => '3 normal', # or PriorityID => 2,
   			State         => 'new',      # or StateID => 5,
   			#CustomerID    => 'alvaro',
   			#CustomerUser  => 'alvaro@gridshield.net',
   			OwnerID       => 1,
   			UserID        => 1,
   	  );
   	  
   #get the last Customer Article
   my %lastArticle = $Self->{TicketObject}->ArticleLastCustomerArticle(
        TicketID      => $Param{Ticket}->{TicketID},
        Extended      => 1,      # 0 or 1, see ArticleGet(),
    );
    
   
        
   my $NewArticleID = $Self->{TicketObject}->ArticleCreate(
            TicketID         => $newTicketID,
            ArticleType      => 'note-internal',
            SenderType       => 'system',         
            Subject          => 'Split from: ('.$Param{Ticket}->{TicketNumber}.'/'.$Param{Ticket}->{TicketID}.')',
            Body             => $lastArticle{Body},
            Charset          => $lastArticle{Charset},
        	MimeType         => $lastArticle{MimeType},
        	HistoryType      => 'OwnerUpdate',  
        	HistoryComment   => 'Split from: ('.$Param{Ticket}->{TicketNumber}.'/'.$Param{Ticket}->{TicketID}.')',
            UserID           => 1,
        );   
        
    # get config for ProcessManagementProcessID dynamic field
	my $fieldConfigPID = $Self->{DynamicFieldObject}->DynamicFieldGet(
		Name => 'ProcessManagementProcessID',
	);    
    # set the value
	my $SuccessPID = $Self->{BackendObject}->ValueSet(
		DynamicFieldConfig => $fieldConfigPID,
		ObjectID           => $newTicketID,
		Value              => $Param{Config}->{process},
		UserID             => 1,
	);  
	
	# get config for ProcessManagementActivityID dynamic field
	my $fieldConfigAID = $Self->{DynamicFieldObject}->DynamicFieldGet(
		Name => 'ProcessManagementActivityID',
	);
	my $SuccessAID = $Self->{BackendObject}->ValueSet(
		DynamicFieldConfig => $fieldConfigAID,
		ObjectID           => $newTicketID,
		Value              => $Param{Config}->{activity},
		UserID             => 1,
	); 
	
	if($Param{Config}->{fields}){
		#get the dynamic Field 
		my %parentTicketSearch = $Self->{TicketObject}->TicketGet(
			TicketID      => $Param{Ticket}->{TicketID},
			DynamicFields => 1,         # Optional, default 0. To include the dynamic field values for this ticket on the return structure.
			UserID        => 1,
			Silent        => 0,         # Optional, default 0. To suppress the warning if the ticket does not exist.
		);
		
		my @ticketDynamicFields = split(',', $Param{Config}->{fields});
		
		foreach my $field (@ticketDynamicFields) {
			if ($parentTicketSearch{"DynamicField_".$field}){
				# get config for ProcessManagementActivityID dynamic field
				my $fieldConfig = $Self->{DynamicFieldObject}->DynamicFieldGet(
					Name => $field,
				);
				my $fieldSuccess = $Self->{BackendObject}->ValueSet(
					DynamicFieldConfig => $fieldConfig,
					ObjectID           => $newTicketID,
					Value              => $parentTicketSearch{"DynamicField_".$field},
					UserID             => 1,
				); 
				$Self->{LogObject}->Log(
					Priority => 'info',
					Message  => "SplitTicket.pm  DynamicField (".$field.")  changed to: ".$parentTicketSearch{"DynamicField_".$field}." child ticket :".$newTicketID,
				);
				if (!$fieldSuccess){
					#something wrong
					$Self->{LogObject}->Log(
						Priority => 'error',
						Message  => "SplitTicket.pm Cannot set  DynamicField (".$field.") value to child ticket :".$newTicketID." , parent ticket: ".$Param{Ticket}->{TicketID},
					);
				}
				
			}else{
				$Self->{LogObject}->Log(
					Priority => 'error',
					Message  => "SplitTicket.pm Cannot add DynamicField to child ticket :".$newTicketID." the parent ticket: ".$Param{Ticket}->{TicketID}." doesn't have DynamicField: ".$field,
				);     
			}
		}
		
    };
	
	# link the tickets
	$Self->{LinkObject}->LinkAdd(
		SourceObject => 'Ticket',
		SourceKey    => $Param{Ticket}->{TicketID},
		TargetObject => 'Ticket',
		TargetKey    => $newTicketID,
		Type         => 'ParentChild',
		State        => 'Valid',
		UserID       => 1,
	);
	
	
	
        
	$Self->{LogObject}->Log(
            Priority => 'info',
            Message  => "SplitTicket.pm Called with parent ticket:".$Param{Ticket}->{TicketID}." done. child ticket: ".$newTicketID." article: ".$NewArticleID,
        );     
    return ;
}
1;
