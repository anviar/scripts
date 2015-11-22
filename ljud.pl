#!/usr/bin/perl -w

##############################################################################
#
# users-agent-LDAP
#
#   Позволяет искать пользователей в LDAP и добавлять их в ростер
#
#############################################################################
my $VERSION = "1.0";

$j_directory="jud.vip-driver.ru";
$j_host="localhost";
$j_port="5347";
$j_secret="secret";
$l_host="localhost";
$l_base="ou=Users,dc=example,dc=local";
$l_filter="(objectClass=posixAccount)";

##############################################################################
#
# Используемые модули Perl
#
##############################################################################
use Net::Jabber 2.0;
use Net::LDAP;
use utf8;
use Getopt::Long;

my %optctl = ();
$optctl{debug} = 0;
&GetOptions(\%optctl, "debug=i","config=s");

my $Debug = new Net::Jabber::Debug(level=>$optctl{debug},
                                   header=>"Драйвер");

##############################################################################
#
# Intercept signals so that we can close down gracefully
#
##############################################################################
$SIG{HUP} = \&Stop;
$SIG{KILL} = \&Stop;
$SIG{TERM} = \&Stop;
$SIG{INT} = \&Stop;


##############################################################################
#
# Global Variables
#
##############################################################################
my %config;
my @routes;

##############################################################################
#
# Форама поиска
#
##############################################################################
my $searchForm = new Net::Jabber::Stanza("x");
$searchForm->SetXMLNS('jabber:x:data');
$searchForm->SetData(instructions=>'Чтобы найти пользователя введите несколько букв из его предпологаемого идентификатора.',
                     title=>'User-Agent Search',
                     type=>'form');
$searchForm->AddField(type=>'text-single',
                      var=>'nick',
                      label=>'Идентификатор');

##############################################################################
#
# Подключаемя к серверу LDAP
#
##############################################################################

$ldap = Net::LDAP->new( $l_host, version=>2 ) or die "$@";
$dtb = $ldap->bind ;

##############################################################################
#
# Создание компонента и соединение с сервером
#
##############################################################################
my $Component = new Net::Jabber::Component(debuglevel=>$optctl{debug});

$Component->Info(name=>"LDAP",
                 version=>$VERSION);

$Component->SetIQCallBacks("jabber:iq:search"=>{
                                                get=>\&iqSearchGetCB,
                                                set=>\&iqSearchSetCB,
                                               },
                           "http://jabber.org/protocol/disco#info"=>{
                                                get=>\&iqDiscoInfoGetCB,
                                               },
                           "http://jabber.org/protocol/disco#items"=>{
                                                get=>\&iqDiscoItemsGetCB,
                                               },
                          );

$Component->SetIQCallBacks(
    "jabber:iq:register"=>
        {
	        get => \&iqRegisterGetCB,
		set => \&iqRegisterSetCB,
	},
    "jabber:iq:gateway"=>
	{
	        get=> \&iqGatewayGetCB,
	        set=> \&iqGatewaySetCB,
	},
    "jabber:iq:version"=>
        {
	        get=> \&iqVersionGetCB,
	},
    "http://jabber.org/protocol/disco#info"=>
	{
	        get=> \&iqDiscoInfoGetCB,
	},
    "http://jabber.org/protocol/disco#items"=>
        {
	        get=> \&iqDiscoItemsGetCB,
	},
); 

$Component->Execute(hostname=>$j_host,
                    port=>$j_port,
                    secret=>$j_secret,
                    componentname=>$j_directory,
                   );
exit(0);


##############################################################################
#
# Завершаем работу и сбрасываем соединения
#
##############################################################################
sub Stop
{
    $Component->Disconnect();
    $ldap->unbind;
    exit(0);
}

##############################################################################
#
# iqSearchGetCB - callback for <iq type='get'... xmlns='jabber:iq:search'
#
##############################################################################
sub iqSearchGetCB
{
    my $sid = shift;
    my $iq = shift;

    my $fromJID = $iq->GetFrom("jid");

    my $iqReply = $iq->Reply(type=>"result");
    my $iqReplyQuery = $iqReply->NewQuery("jabber:iq:search");
    $iqReplyQuery->SetSearch(instructions=>"Введите предполагаемый id нужного сотрудника.",
                             nick=>"");

    $Debug->Log1("iqSearchGetCB: reply(",$iqReply->GetXML(),")");
    $Debug->Log1("iqSearchGetCB: searchForm(",$searchForm->GetXML(),")");
    $iqReplyQuery->AddChild($searchForm);
    $Component->Send($iqReply);
}


##############################################################################
#
# iqSearchSetCB - callback for <iq type='set'... xmlns='jabber:iq:search'
#
##############################################################################
sub iqSearchSetCB
{ 
    my $sid = shift;
    my $iq = shift;
    $Debug->Log1("iqSearchSetCB: iq(",$iq->GetXML(),")");

    my $fromJID = $iq->GetFrom("jid");
    my $query = $iq->GetChild();

    my $iqReply = $iq->Reply(type=>"result");
    my $iqReplyQuery = $iqReply->GetChild("jabber:iq:search");

    my @commands;

    my @xData = $query->GetChild("jabber:x:data");
    
    my $hasForm = 0;
    if ($#xData > -1)
    {
        $hasForm = 1;
        my $likeSpeed = "";
        foreach my $field ($xData[0]->GetFields())
        {
            next unless ($field->GetVar() eq "speed");
            if ($field->GetValue() eq "slow")
            {
                $likeSpeed = "%";
            }	
        }

        foreach my $field ($xData[0]->GetFields())
        {
            next if ($field->GetValue() eq "");
	    
            next if ($field->GetVar() eq "speed");
        }
    

    
#	Формируем фильтры для запроса
	$t_attr=$xData[0]->GetFields()->GetValue();
	if ( $t_attr )	{$search_attrs="(uid=*".$t_attr."*)";} 
	else 			{$search_attrs="";};	
    }
	else {$search_attrs="";};
	
	$dtb = $ldap->search( # perform a search
	                          base   => $l_base,
				  filter => "(&".$l_filter.$search_attrs.")",
				  attrs => [ "cn","uid", "mail" ]
				);
	$dtb->code && die $dtb->error;

        my $resultsReport;
        if ($hasForm)
        {
            $resultsReport = $iqReplyQuery->NewX("jabber:x:data");
            $resultsReport->SetData(type=>'result',
                                    title=>"Users-Agent Search Results");
            my $reported = $resultsReport->AddReported();
            $reported->AddField(var=>'jid',
                                type=>'jid-single',
                                label=>'JID');
            $reported->AddField(var=>'name',
                                label=>'Имя');
            $reported->AddField(var=>'nick',
                            label=>'Идентификатор');
            $reported->AddField(var=>'email',
                                label=>'Email');
        }
        
        my $count = 0;
        foreach $ldap_entry ($dtb->entries)
        {
	$name_prepared=	$ldap_entry->get_value('cn');
	utf8::decode($name_prepared);
            if ($hasForm == 0)
            {
                $iqReplyQuery->AddItem(jid=>$ldap_entry->get_value('uid')."\@vip-driver.ru",
                                       name=>$name_prepared,
                                       nick=>$ldap_entry->get_value('uid'),
                                       email=>$ldap_entry->get_value('mail'));
            }
            else
            {
                my $item = $resultsReport->AddItem();
                $item->AddField(var=>"jid",
                                value=>$ldap_entry->get_value('uid')."\@vip-driver.ru");
                $item->AddField(var=>"name",
                                value=>$name_prepared);
                $item->AddField(var=>"nick",
                                value=>$ldap_entry->get_value('uid'));
                $item->AddField(var=>"email",
                                value=>$ldap_entry->get_value('mail'));
            }
            $count++;
        }
        $iqReplyQuery->SetTruncated();

    $Component->Send($iqReply);
}


##############################################################################
#
# iqDiscoInfoGetCB - callback for disco
#
##############################################################################
sub iqDiscoInfoGetCB
{
    my $sid = shift;
    my $iq = shift;
    my $fromJID = $iq->GetFrom("jid");

    my $iqReply = $iq->Reply(type=>"result");
    my $iqReplyQuery = $iqReply->NewQuery("http://jabber.org/protocol/disco#info");
    #$iqReplyQuery->AddIdentity($j_directory,
    $iqReplyQuery->AddIdentity( category => "directory",
                               type=>"user",
                               name=>"Поиск пользователей"
                              );
    $iqReplyQuery->AddFeature(var=>"jabber:iq:search");
    $Component->Send($iqReply);
}



##############################################################################
#
# iqDiscoItemsGetCB - callback for disco
#
##############################################################################
sub iqDiscoItemsGetCB
{
    my $sid = shift;
    my $iq = shift;
		
    my $toJID = $iq->GetTo("jid");
    my $fromJID = $iq->GetFrom("jid");
    my $query = $iq->GetChild("http://jabber.org/protocol/disco#items");

    my $iqReply = $iq->Reply(type=>"result");
    my $iqReplyQuery = $iqReply->GetChild("http://jabber.org/protocol/disco#items");
				    
    $Component->Send($iqReply);
}
