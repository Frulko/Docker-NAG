#--------------------------------------------------------------
# NAG - Net.Art Generator
#
# Author: Panos Galanis <pg@iap.de>
# Created: 16.04.2003
# Last: 10.06.2003
# License: GNU GPL (GNU General Public License. See LICENSE file) 
#
# Copyright (C) 2003 IAP GmbH 
# Ingenieurb�ro f�r Anwendungs-Programmierung
# M�rkenstra�e 9, D-22767 Hamburg
# Web: http://www.iap.de, Mail: info@iap.de 
#--------------------------------------------------------------
#--------------------------------------------------------------
# NAG - Net.Art Generator (updated version: fixed Google search API + others)
#
# Co-Author: Winnie Soon <rwx[at]siusoon.net>
# Last: 17.08.2017
# Web: www.siusoon.net
#--------------------------------------------------------------
#
# Netagent.pl
#

sub doLog
{
    open(FLOG,">>/tmp/jclog.log");
    print FLOG "@_\n";
    close(FLOG);
}

# apparently no use for getURL /Winnie
#------------------------------------
#sub getURL
#{
#    my $cmd = "nice -n 19 lynx -force_secure -accept-all-cookies -source '@_'";
#    my $cmd = "nice -n 19 w3m -dump '@_'";
#    open(FIN,"$cmd|");
#    while(<FIN>)
#    {
#        $page.=$_;
#    }
#    close(FIN);
#    return $page;
#}
#------------------------------------

# apparently no use for getPage /Winnie
#------------------------------------
#sub getPage
#{
    #my $query="@_";
    #
    #my $ua = LWP::UserAgent->new;
    ##$ua->proxy(http  => 'http://proxy.server:80');
    #$ua->agent("Mozilla/5.0");
    #my $req = HTTP::Request->new(GET => "http://images.google.com/images?hl=en&output=search&safe=active&q=". $query);
    #return $ua->request($req)->as_string;
#    my $searchterm="@_";
#    my $query="https://www.google.com/search?hl=en&output=search&safe=active&tbm=isch&q=". $searchterm;
#    my $query="https://www.google.com/search?safe=active&tbm=isch&source=hp&q=". $searchterm;    
#    return getURL($query);
#}
#------------------------------------


#---new Google API--------------------
sub getImgList
{
  
#----search criteria------
  #my $url = "https://www.googleapis.com/customsearch/v1?key=AIzaSyD71g7MfDSbZ1DEN6ChRkgpOnqn-QsfNc0&cx=009687617620501668171:er1ubtpqt94&q=NET+ART+GENERATOR&searchType=image&fileType=jpg&imgSize=xxlarge";
  my $api = "https://www.googleapis.com/customsearch/v1?";
  my $key = 'AIzaSyD71g7MfDSbZ1DEN6ChRkgpOnqn-QsfNc0';  #NAG
  my $cx = '009687617620501668171:er1ubtpqt94'; #NAG
  my $searchType = 'image';
  my $query = shift;
  my $fileType = shift;
  my $imgSize ='xxlarge';
  my $url = $api . "key=" . $key . "&cx=" . $cx . "&q=" . $query . "&searchType=" . $searchType . "&fileType=" . $fileType . "&imgSize="  . $imgSize;
#----End of search criteria------
  my $ua = LWP::UserAgent->new; 
  my $request = HTTP::Request->new("GET" => $url);
  my $response = $ua->request($request);
  my @ilinks=();
  my $message = $response->decoded_content;
  my $returned_query = decode_json($message); #
  
  if ($response->is_success) {
	my $extract1 = $returned_query->{items};	
    for my $pick (@$extract1) {
       push(@ilinks, "$pick->{link}");
	}		         
  }else{	#unsuccessful query with error code checking
 	my $extract2 = $returned_query->{error}->{errors}->[0]->{reason};
 	my $extract3 = $returned_query->{error}->{code};
  	push(@ilinks,"$extract2") if (($extract2 eq "dailyLimitExceeded") && ($extract3 == 403)); #dailyLimitExceeded and error code 403 - msg by Google	 
  }
  return @ilinks; #@ilinks will be either blank (other kinds of unknown error), or with links (valid query), or error msg by Google
}
#---end of new Google API parsing--------------------

sub grabImg {

doLog("\n\nGrabbing images");
    my @list=();
    my $no=0;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0");
    foreach (@_) {
        my $file = $_;
        my $chk=0;
        my $chkd=0;
        $file =~ s/[^\w\d\.]/_/g;
        my $saved_path = "./grab/" . $file;         
        if (!-e ">$saved_path" || $chkd) {
doLog("Grabbing file");
            #print "Getting <b>$_</b> saving as <em>$file</em><br>\n";
            my $req = HTTP::Request->new(GET => "$_");
            my $pic = $ua->request($req);  
doLog("Headers: ".$pic->headers->as_string);
            $chk=($pic->headers->as_string =~ m/content-type: image\//i);
            if ($chk) 
            {
doLog("Saving file");    
                open(FH, ">$saved_path") || die "Cant Open $saved_path :$!\n";
                #binmode FH;  # for MSDOS derivations.
                print FH $pic->content;
                close(FH);
doLog("Saving done");    
            }
        }else{
doLog("File in cache??");
            $chk=1;
            $no++;
        }
        push(@list, "$saved_path") if $chk;
    }
    return ($no, @list);
}

1;

