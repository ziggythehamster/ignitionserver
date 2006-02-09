Attribute VB_Name = "mod_list"
'ignitionServer is (C) Keith Gable and Contributors
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'Contributors:        Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'                     Reid Burke  (Airwalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: mod_list.bas,v 1.41 2004/07/02 23:16:55 ziggythehamster Exp $
'
'
'This program is free software.
'You can redistribute it and/or modify it under the terms of the
'GNU General Public License as published by the Free Software Foundation; either version 2 of the License,
'or (at your option) any later version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
'Without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
'See the GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License along with this program.
'if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Option Explicit
'this is kind of an internal flood limiter
'100 is the highest this number should be
'10 is the lowest this number should be
'this number can not be 1 or less
Public Const MaxTrafficRate As Long = 100

'-=BUILD DATE=-
Public Const BuildDate As String = "20040702"

#Const Debugging = 0

Public Type IrcStats
  UnknownConnections As Long
  Channels As Long
  GlobUsers As Long
  LocUsers As Long
  GlobServers As Long
  LocServers As Long
  MaxLocUsers As Long
  MaxGlobUsers As Long
  Invisible As Long
  Operators As Long
  Connections As Long
End Type

'MAIN SYSTEM OBJECTS
Public Sockets As clsSox             'provides the nessacery connectivity
Public Users() As clsClient          'For Local users only, to map Connections to Objects
Public Channels As clsChanHashTable
Public Servers As clsServerHashTable
Public GlobUsers As clsUserHashTable 'For Global AND Local users

'Opers/Servermsg/Killmsg/GlobOps/LocOps
'so we do not have to loop through all users to
'check if they're marked for reciept of certains msg's
'and/or allowed to do certain things
Public Opers As clsUserHashTable
Public ServerMsg As clsUserHashTable
Public WallOps As clsUserHashTable
Public IPHash As clsIPHashTable

'server crap
Public ServerLocalAddr As String
Public ServerLocalPort As String

'Statistics variables/Cache
Public LocalConn&, RecvMsg&, SentMsg&
Public IrcStat As IrcStats, Cmds As Commands
Public UnixTime&, ServerTraffic As Double
Public hTmrUnixTime&, hTmrDestroyWhoWas&
Public ServerName$, ServerDescription$
Public MotD$, IRCNet$, ColOutClientMsg As New Collection
Public StartUp&, SPrefix$, StartUpUt&, Ports&, StartUpDate$
Public AppVersion As String, AppComments As String

'S:MaxConn:MaxClones:MaxChans:NickLen:TopicLen:KickLen:PartLen:KeyLen:QuitLen:MaxWhoLen:MaxListLen
'Security Line - Added 22nd Feb 2003 by dilligent
Public MaxConnections As Long
Public MaxConnectionsPerIP As Long
Public MaxChannelsPerUser As Long
Public NickLen As Long
Public TopicLen As Long
Public KickLen As Long
Public PartLen As Long
Public KeyLen As Long
Public QuitLen As Long
Public MaxWhoLen As Long
Public MaxListLen As Long
Public MaxMsgsInQueue As Long

'registered channel mode
Public RegChanMode_Always As Boolean
Public RegChanMode_Never As Boolean
Public RegChanMode_ModeR As Boolean

'Auto VHost
Public AVHost As Boolean

'SVSNicks
Public SVSN_NickServ As String
Public SVSN_ChanServ As String

'IRCX Method
Public IRCXM_Trans As Boolean
Public IRCXM_Strict As Boolean
Public IRCXM_Both As Boolean

'GagModes
Public ShowGag As Boolean
Public BounceGagMsg As Boolean

'/die and /restart passwords
Public RestartPass As String
Public DiePass As String

'allow mulitple instances
Public AllowMultiple As Boolean

'enable maskdns
Public MaskDNS As Boolean
Public MaskDNSMD5 As Boolean
Public MaskDNSHOST As Boolean
Public HostMask As String

'Protect Stuff
Public HighProtAsq As Boolean
Public LowProtAsq As Boolean
Public HighProtAso As Boolean
Public LowProtAso As Boolean
Public HighProtAsv As Boolean
Public LowProtAsv As Boolean
Public HighProtAsn As Boolean
Public LowProtAsn As Boolean

'Server location
Public ServerLocation As String

'Auto Kill For Missconfigured servers...
Public Die As Boolean

'Remote Access Pass(To get special features
Public RemotePass

'Enable Error Log
Public ErrorLog As Boolean

'Offline Mode
Public OfflineMode As Boolean
Public OfflineMessage As String

'Custom Message
Public CustomNotice As String

'Crypt
Public Crypt As Boolean
Public MD5Crypt As Boolean

'HTM - High Traffic Mode
'Added 2nd feb 2003 by dilligent to handle Oper/server sendq's more efficiently
Public htm As Boolean

'Admin Info
Public Admin As String
Public AdminLocation As String
Public AdminEmail As String
Public AdminInfo1 As String
Public AdminInfo2 As String

Public Portal As typPortal

Public Type ClientsVisible
    index As Long
    Nickname As String
End Type

Public Type typPortal 'Class specific variables
    hWnd As Long 'The handle to the window we create on initialization that will receive WinSock messages
    WndProc As Long 'Pointer to the origional WindowProc of our window (We need to give control of ALL messages back to it before we destroy it)
    Sockets As Long 'How many Sockets are comming through the Portal, Actually hold the Socket array count. NB - MUST change with Redim of Sockets
End Type

Public Enum ChanMemberFlags
  ChanOwnerVoice = 7
  ChanOwner = 6
  ChanOpVoice = 5
  ChanOp = 4
  'ChanHOpVoice = 3
  'ChanHOp = 2
  ChanVoice = 1
  ChanNormal = 0
End Enum

Public Enum enmType
    enmTypeClient = 1
    enmTypeServer = 2
    enmTypeChannel = 3
End Enum

Public Type LLines
  Host As String
  Pass As String
  Server As String
  Port As Long
  ConnectionClass As Long
End Type

'Public Type CLines - Coming Soon to a Server Near You! - DG
'
'End Type

Public Type KLines
  Host As String
  User As String
  Reason As String
End Type

Public Type ILines
  IP As String
  Pass As String
  Host As String
  ConnectionClass As Long
End Type

Public Type YLines
  ID As Long
  index As Long
  PingFreq As Long
  PingCounter As Long
  ConnectFreq As Long
  MaxClients As Long
  CurClients As Long
  MaxSendQ As Long
End Type

Public Type OLines
  Host As String
  Pass As String
  Name As String
  AccessFlag As String
  ConnectionClass As Long
  CanDie As Boolean
  CanRestart As Boolean
  CanRehash As Boolean
  CanGlobOps As Boolean
  CanLocOps As Boolean
  CanLocRouting As Boolean
  CanGlobRouting As Boolean
  CanLocKill As Boolean
  CanGlobKill As Boolean
  CanJoin As Boolean
End Type

Public Type VLines
  Host As String
  Pass As String
  Name As String
  Vhost As String
End Type

Public Type QLines
  Nick As String
  Reason As String
End Type

Public Type PLines
  IP As String
  PortOption As String
  Port As String
End Type

Public Type ZLines
  IP As String
  Reason As String
End Type

Public Type Commands
  Pass As Long: PassBW As Currency
  Nick As Long: NickBW As Currency
  User As Long: UserBW As Currency
  Version As Long: VersionBW As Currency
  MotD As Long: MotDBW As Currency
  Lusers As Long: LusersBW As Currency
  Join As Long: JoinBW As Currency
  Part As Long: PartBW As Currency
  Privmsg As Long: PrivmsgBW As Currency
  Notice As Long: NoticeBW As Currency
  Quit As Long: QuitBW As Currency
  Stats As Long: StatsBW As Currency
  Ircx As Long: IrcxBW As Currency
  Ison As Long: IsonBW As Currency
  Oper As Long: OperBW As Currency
  List As Long: ListBW As Currency
  Squit As Long: SquitBW As Currency
  Connect As Long: ConnectBW As Currency
  Kill As Long: KillBW As Currency
  Akill As Long: AkillBW As Currency
  KLine As Long: KlineBW As Currency
  Mode As Long: ModeBW As Currency
  Kick As Long: KickBw As Currency
  Topic As Long: TopicBW As Currency
  UserHost As Long: UserHostBW As Currency
  Invite As Long: InviteBW As Currency
  Ping As Long: PingBW As Currency
  Pong As Long: PongBW As Currency
  Whois As Long: WhoisBW As Currency
  Time As Long: TimeBW As Currency
  Info As Long: InfoBW As Currency
  Away As Long: AwayBW As Currency
  Links As Long: LinksBW As Currency
  Map As Long: MapBW As Currency
  Names As Long: NamesBW As Currency
  Admin As Long: AdminBW As Currency
  Who As Long: WhoBW As Currency
  Die As Long: DieBW As Currency
  Restart As Long: RestartBW As Currency
  Rehash As Long: RehashBW As Currency
  NickServ As Long: NickServBW As Currency
  ChanServ As Long: ChanServBW As Currency
  MemoServ As Long: MemoServBW As Currency
  OperServ As Long: OperServBW As Currency
  ChanPass As Long: ChanPassBW As Currency
  Prop As Long: PropBW As Currency
  Server As Long: ServerBW As Currency
  WhoWas As Long: WhoWasBW As Currency
  Hash As Long: HashBW As Currency
  Close As Long: CloseBW As Currency
  SAMode As Long: SAModeBW As Currency
  UMode As Long: UModeBW As Currency
  UnKLine As Long: UnKlineBW As Currency
  Auth As Long: AuthBW As Currency
  Help As Long: HelpBW As Currency
  PassCrypt As Long: PassCryptBW As Currency
  Chghost As Long: ChghostBW As Currency
  ListX As Long: ListXBW As Currency
  Access As Long: AccessBW As Currency
  Create As Long: CreateBW As Currency
  ChgNick As Long: ChgNickBW As Currency
  Add As Long: AddBW As Currency
  Whisper As Long: WhisperBW As Currency
End Type

'/*
' * Reserve numerics 000-099 for server-client connections where the client
' * is local to the server. If any server is passed a numeric in this range
' * from another server then it is remapped to 100-199.
' */

Public Const RPL_WELCOME As Long = 1
Public Const RPL_YOURHOST As Long = 2
Public Const RPL_CREATED As Long = 3
Public Const RPL_MYINFO As Long = 4
Public Const RPL_PROTOCTL As Long = 5

'/*
' * Errors are in the range from 400-599 currently and are grouped by what
' * commands they come from.
' */
Public Const ERR_NOSUCHNICK As Long = 401
Public Const ERR_NOSUCHSERVER As Long = 402
Public Const ERR_NOSUCHCHANNEL As Long = 403
Public Const ERR_CANNOTSENDTOCHAN As Long = 404
Public Const ERR_TOOMANYCHANNELS As Long = 405
Public Const ERR_WASNOSUCHNICK As Long = 406
Public Const ERR_TOOMANYTARGETS As Long = 407
Public Const ERR_NOSUCHSERVICE As Long = 408
Public Const ERR_NOORIGIN As Long = 409

Public Const ERR_NORECIPIENT As Long = 411
Public Const ERR_NOTEXTTOSEND As Long = 412
Public Const ERR_NOTOPLEVEL As Long = 413
Public Const ERR_WILDTOPLEVEL As Long = 414

Public Const ERR_UNKNOWNCOMMAND As Long = 421
Public Const ERR_NOMOTD As Long = 422
Public Const ERR_NOADMININFO As Long = 423
Public Const ERR_FILEERROR As Long = 424
Public Const ERR_NOOPERMOTD As Long = 425
Public Const ERR_NONICKNAMEGIVEN As Long = 431
Public Const ERR_ERRONEUSNICKNAME As Long = 432
Public Const ERR_NICKNAMEINUSE As Long = 433
Public Const ERR_NORULES As Long = 434
Public Const ERR_SERVICECONFUSED As Long = 435
Public Const ERR_NICKCOLLISION As Long = 436
Public Const ERR_BANNICKCHANGE As Long = 437
Public Const ERR_NCHANGETOOFAST As Long = 438
Public Const ERR_TARGETTOOFAST As Long = 439
Public Const ERR_SERVICESDOWN As Long = 440

Public Const ERR_USERNOTINCHANNEL As Long = 441
Public Const ERR_NOTONCHANNEL As Long = 442
Public Const ERR_USERONCHANNEL As Long = 443
Public Const ERR_NOLOGIN As Long = 444
Public Const ERR_SUMMONDISABLED As Long = 445
Public Const ERR_USERSDISABLED As Long = 446

Public Const ERR_NOTREGISTERED As Long = 451

Public Const ERR_HOSTILENAME As Long = 455

Public Const ERR_NOHIDING As Long = 459
Public Const ERR_NOTFORHALFOPS As Long = 460
Public Const ERR_NEEDMOREPARAMS As Long = 461
Public Const ERR_ALREADYREGISTRED As Long = 462
Public Const ERR_NOPERMFORHOST As Long = 463
Public Const ERR_PASSWDMISMATCH As Long = 464
Public Const ERR_YOUREBANNEDCREEP As Long = 465
Public Const ERR_YOUWILLBEBANNED As Long = 466
Public Const ERR_KEYSET As Long = 467
Public Const ERR_ONLYSERVERSCANCHANGE As Long = 468
Public Const ERR_LINKSET As Long = 469
Public Const ERR_LINKCHANNEL As Long = 470
Public Const ERR_CHANNELISFULL As Long = 471
Public Const ERR_UNKNOWNMODE As Long = 472
Public Const ERR_INVITEONLYCHAN As Long = 473
Public Const ERR_BANNEDFROMCHAN As Long = 474
Public Const ERR_BADCHANNELKEY As Long = 475
Public Const ERR_BADCHANMASK As Long = 476
Public Const ERR_NEEDREGGEDNICK As Long = 477
Public Const ERR_BANLISTFULL As Long = 478
Public Const ERR_LINKFAIL As Long = 479
Public Const ERR_CANNOTKNOCK As Long = 480

Public Const ERR_NOPRIVILEGES As Long = 481
Public Const ERR_CHANOPRIVSNEEDED As Long = 482
Public Const ERR_CANTKILLSERVER As Long = 483
Public Const ERR_ATTACKDENY As Long = 484
Public Const ERR_KILLDENY As Long = 485

Public Const ERR_HTMDISABLED As Long = 486

Public Const ERR_NOOPERHOST As Long = 491
Public Const ERR_NOSERVICEHOST As Long = 492

Public Const ERR_UMODEUNKNOWNFLAG As Long = 501
Public Const ERR_USERSDONTMATCH As Long = 502

Public Const ERR_SILELISTFULL As Long = 511
Public Const ERR_TOOMANYWATCH As Long = 512
Public Const ERR_NEEDPONG As Long = 513

Public Const ERR_NOINVITE As Long = 518
Public Const ERR_ADMONLY As Long = 519
Public Const ERR_OPERONLY As Long = 520
Public Const ERR_LISTSYNTAX As Long = 521

'** IRCX **
' (added by Ziggy)

'Replies:
Public Const IRCRPL_IRCX As Long = 800
Public Const IRCRPL_ACCESSADD As Long = 801
Public Const IRCRPL_ACCESSDELETE As Long = 802
Public Const IRCRPL_ACCESSSTART As Long = 803
Public Const IRCRPL_ACCESSLIST As Long = 804
Public Const IRCRPL_ACCESSEND As Long = 805
Public Const IRCRPL_EVENTADD As Long = 806
Public Const IRCRPL_EVENTDEL As Long = 807
Public Const IRCRPL_EVENTSTART As Long = 808
Public Const IRCRPL_EVENTLIST As Long = 809
Public Const IRCRPL_EVENTEND As Long = 810
Public Const IRCRPL_LISTXSTART As Long = 811
Public Const IRCRPL_LISTXLIST As Long = 812
Public Const IRCRPL_LISTXPICS As Long = 813
Public Const IRCRPL_LISTXTRUNC As Long = 816
Public Const IRCRPL_LISTXEND As Long = 817
Public Const IRCRPL_PROPLIST As Long = 818
Public Const IRCRPL_PROPEND As Long = 819

'Errors:
Public Const IRCERR_BADCOMMAND As Long = 900
Public Const IRCERR_TOOMANYARGUMENTS As Long = 901
Public Const IRCERR_BADFUNCTION As Long = 902
Public Const IRCERR_BADLEVEL As Long = 903
Public Const IRCERR_BADTAG As Long = 904
Public Const IRCERR_BADPROPERTY As Long = 905
Public Const IRCERR_BADVALUE As Long = 906
Public Const IRCERR_RESOURCE As Long = 907
Public Const IRCERR_SECURITY As Long = 908
Public Const IRCERR_ALREADYAUTHENTICATED As Long = 909
Public Const IRCERR_AUTHENTICATIONFAILED As Long = 910
Public Const IRCERR_AUTHENTICATIONSUSPENDED As Long = 911
Public Const IRCERR_UNKNOWNPACKAGE As Long = 912
Public Const IRCERR_NOACCESS As Long = 913
Public Const IRCERR_DUPACCESS As Long = 914
Public Const IRCERR_MISACCESS As Long = 915 'Unknown access entry
Public Const IRCERR_TOOMANYACCESSES As Long = 916
Public Const IRCERR_EVENTDUP As Long = 918
Public Const IRCERR_EVENTMIS As Long = 919
Public Const IRCERR_NOSUCHEVENT As Long = 920
Public Const IRCERR_TOOMANYEVENTS As Long = 921
Public Const IRCERR_ACCESSSECURITY As Long = 922 'not specifically mentioned in the draft
Public Const IRCERR_NOWHISPER As Long = 923
Public Const IRCERR_NOSUCHOBJECT As Long = 924
Public Const IRCERR_NOTSUPPORTED As Long = 925
Public Const IRCERR_CHANNELEXIST As Long = 926
Public Const IRCERR_ALREADYONCHANNEL As Long = 927
Public Const IRCERR_UNKNOWNERROR As Long = 999

'/*
' * Numberic replies from server commands.
' * These are currently in the range 200-399.
' */
Public Const RPL_NONE As Long = 300
Public Const RPL_AWAY As Long = 301
Public Const RPL_USERHOST As Long = 302
Public Const RPL_ISON As Long = 303
Public Const RPL_TEXT As Long = 304
Public Const RPL_UNAWAY As Long = 305
Public Const RPL_NOWAWAY As Long = 306

'Public Const RPL_RULESSTART As Long = 308 '// what the hell are these?
'Public Const RPL_ENDOFRULES As Long = 309 '// ""

'/whois stuff
Public Const RPL_WHOISREGNICK As Long = 307
Public Const RPL_WHOISADMIN As Long = 308 'NetAdmin
Public Const RPL_WHOISSADMIN As Long = 309 'Service Admin (need mode for this)
Public Const RPL_WHOISHELPOP As Long = 310     '/* -Donwulff */
Public Const RPL_WHOISUSER As Long = 311
Public Const RPL_WHOISSERVER As Long = 312
Public Const RPL_WHOISOPERATOR As Long = 313

Public Const RPL_WHOWASUSER As Long = 314
Public Const RPL_ENMDOFWHO As Long = 315

Public Const RPL_WHOISCHANOP As Long = 316     '/* redundant and not needed but reserved */
Public Const RPL_WHOISIDLE As Long = 317

Public Const RPL_ENDOFWHOIS As Long = 318
Public Const RPL_WHOISCHANNELS As Long = 319
Public Const RPL_WHOISSPECIAL As Long = 320
Public Const RPL_LISTSTART As Long = 321
Public Const RPL_LIST As Long = 322
Public Const RPL_LISTEND As Long = 323
Public Const RPL_CHANNELMODEIS As Long = 324
Public Const RPL_CREATIONTIME As Long = 329
Public Const RPL_NOTOPIC As Long = 331
Public Const RPL_TOPIC As Long = 332
Public Const RPL_TOPICWHOTIME As Long = 333

Public Const RPL_LISTSYNTAX As Long = 334
Public Const RPL_WHOISBOT As Long = 335
Public Const RPL_INVITING As Long = 341
Public Const RPL_SUMMONING As Long = 342

Public Const RPL_VERSION As Long = 351

Public Const RPL_WHOREPLY As Long = 352
Public Const RPL_ENDOFWHO As Long = 315
Public Const RPL_NAMREPLY As Long = 353
Public Const RPL_ENDOFNAMES As Long = 366
Public Const RPL_INVITELIST As Long = 346
Public Const RPL_ENDOFINVITELIST As Long = 347

Public Const RPL_EXLIST As Long = 348
Public Const RPL_ENDOFEXLIST As Long = 349
Public Const RPL_KILLDONE As Long = 361
Public Const RPL_CLOSING As Long = 362
Public Const RPL_CLOSEEND As Long = 363
Public Const RPL_LINKS As Long = 364
Public Const RPL_ENDOFLINKS As Long = 365
Public Const RPL_BANLIST As Long = 367
Public Const RPL_ENDOFBANLIST As Long = 368
Public Const RPL_ENDOFWHOWAS As Long = 369

Public Const RPL_INFO As Long = 371
Public Const RPL_MOTD As Long = 372
Public Const RPL_INFOSTART As Long = 373
Public Const RPL_ENDOFINFO As Long = 374
Public Const RPL_MOTDSTART As Long = 375
Public Const RPL_ENDOFMOTD As Long = 376

Public Const RPL_WHOISHOST As Long = 378
Public Const RPL_WHOISMODES As Long = 379
Public Const RPL_YOUREOPER As Long = 381
Public Const RPL_REHASHING As Long = 382
Public Const RPL_YOURESERVICE As Long = 383
Public Const RPL_MYPORTIS As Long = 384
Public Const RPL_NOTOPERANYMORE As Long = 385
Public Const RPL_QLIST As Long = 386
Public Const RPL_ENDOFQLIST As Long = 387
Public Const RPL_ALIST As Long = 388
Public Const RPL_ENDOFALIST As Long = 389

Public Const RPL_TIME As Long = 391
Public Const RPL_USERSSTART As Long = 392
Public Const RPL_USERS As Long = 393
Public Const RPL_ENDOFUSERS As Long = 394
Public Const RPL_NOUSERS As Long = 395

Public Const RPL_TRACELINK As Long = 200
Public Const RPL_TRACECONNECTING As Long = 201
Public Const RPL_TRACEHANDSHAKE As Long = 202
Public Const RPL_TRACEUNKNOWN As Long = 203

Public Const RPL_TRACEOPERATOR As Long = 204
Public Const RPL_TRACEUSER As Long = 205
Public Const RPL_TRACESERVER As Long = 206
Public Const RPL_TRACESERVICE As Long = 207
Public Const RPL_TRACENEWTYPE As Long = 208
Public Const RPL_TRACECLASS As Long = 209

Public Const RPL_STATSLINKINFO As Long = 211
Public Const RPL_STATSCOMMANDS As Long = 212
Public Const RPL_STATSCLINE As Long = 213
Public Const RPL_STATSNLINE As Long = 214
Public Const RPL_STATSILINE As Long = 215
Public Const RPL_STATSKLINE As Long = 216
Public Const RPL_STATSQLINE As Long = 217
Public Const RPL_STATSYLINE As Long = 218
Public Const RPL_ENDOFSTATS As Long = 219
Public Const RPL_STATSBLINE As Long = 220


Public Const RPL_UMODEIS As Long = 221
Public Const RPL_SQLINE_NICK As Long = 222
Public Const RPL_STATSGLINE As Long = 223
Public Const RPL_STATSTLINE As Long = 224
Public Const RPL_SERVICEINFO As Long = 231
Public Const RPL_RULES As Long = 232
Public Const RPL_SERVICE As Long = 233
Public Const RPL_SERVLIST As Long = 234
Public Const RPL_SERVLISTEND As Long = 235

Public Const RPL_STATSLLINE As Long = 241
Public Const RPL_STATSUPTIME As Long = 242
Public Const RPL_STATSOLINE As Long = 243
Public Const RPL_STATSHLINE As Long = 244
Public Const RPL_STATSSLINE As Long = 245
Public Const RPL_STATSXLINE As Long = 247
Public Const RPL_STATSULINE As Long = 248
Public Const RPL_STATSDEBUG As Long = 249
Public Const RPL_STATSCONN As Long = 250

Public Const RPL_LUSERCLIENT As Long = 251
Public Const RPL_LUSEROP As Long = 252
Public Const RPL_LUSERUNKNOWN As Long = 253
Public Const RPL_LUSERCHANNELS As Long = 254
Public Const RPL_LUSERME As Long = 255
Public Const RPL_ADMINME As Long = 256
Public Const RPL_ADMINLOC1 As Long = 257
Public Const RPL_ADMINLOC2 As Long = 258
Public Const RPL_ADMINEMAIL As Long = 259

Public Const RPL_TRACELOG As Long = 261
Public Const RPL_LOCALUSERS As Long = 265
Public Const RPL_GLOBALUSERS As Long = 266

Public Const RPL_SILELIST As Long = 271
Public Const RPL_ENDOFSILELIST As Long = 272
Public Const RPL_STATSDLINE As Long = 275

Public Const RPL_HELPHDR As Long = 290
Public Const RPL_HELPOP As Long = 291
Public Const RPL_HELPTLR As Long = 292
Public Const RPL_HELPHLP As Long = 293
Public Const RPL_HELPFWD As Long = 294
Public Const RPL_HELPIGN As Long = 295

'/*
' * New /MAP format.
' */
Public Const RPL_MAP As Long = 6
Public Const RPL_MAPMORE As Long = 610
Public Const RPL_MAPEND As Long = 7

'/*
' * Numberic replies from server commands.
' * These are also in the range 600-799.
' */
Public Const RPL_LOGON As Long = 600
Public Const RPL_LOGOFF As Long = 601
Public Const RPL_WATCHOFF As Long = 602
Public Const RPL_WATCHSTAT As Long = 603
Public Const RPL_NOWON As Long = 604
Public Const RPL_NOWOFF As Long = 605
Public Const RPL_WATCHLIST As Long = 606
Public Const RPL_ENDOFWATCHLIST As Long = 607
Public Const RPL_DUMPING As Long = 640
Public Const RPL_DUMPRPL As Long = 641
Public Const RPL_EODUMP As Long = 642

'Hash constants
Public Const RPL_HASH As Long = 700
Public Const RPL_ENDOFHASH As Long = 701

'*** Chan Modes (ASCII values of the mode char's for faster processing) ***
'Channel user levels
Public Const cmBan As Long = 98               '+b / ban
Public Const cmOp As Long = 111               '+o / host
Public Const cmOwner As Long = 113            '+q / owner
Public Const cmVoice As Long = 118            '+v / voice

'Lowercase
Public Const cmHidden As Long = 104           '+h / hidden
Public Const cmInviteOnly As Long = 105       '+i / invite only
Public Const cmKey As Long = 107              '+k / password
Public Const cmLimit As Long = 108            '+l / limit
Public Const cmModerated As Long = 109        '+m / moderated
Public Const cmNoExternalMsg As Long = 110    '+n / noextern
Public Const cmPrivate As Long = 112          '+p / private
Public Const cmRegistered As Long = 114       '+r / registered
Public Const cmSecret As Long = 115           '+s / secret
Public Const cmOpTopic As Long = 116          '+t / only ops change topic
Public Const cmKnock As Long = 117            '+u / knock
Public Const cmAuditorium As Long = 120       '+x / auditorium

'Uppercase
Public Const cmOperOnly As Long = 79          '+O / oper only
Public Const cmPersistant As Long = 82        '+R / persistant


'+/- Mode Operators
Public Const modeAdd As Long = 43
Public Const modeRemove As Long = 45

'All possible modes for chan/user
'Now in alphabetical order - Ziggy
'Added missing modes
Public Const UserModes As String = "bcdeikoprswxzBCDEHKNOPRSWZ"
Public Const ChanModes As String = "bhiklmnopqrstuvOR"
'for the 005 reply
Public Const ChanModesX As String = "b,k,l,himnopqrstuvOR"

'Authentication Packages/IRCX stuff
Public Const AuthPackages As String = "ANON"
Public Const Capabilities As String = "*"

'User Modes (ASCII values of the mode char's for faster processing)

'Upper Case

Public Const umCanUnKline As Long = 66  '+B / Can /unkline user
Public Const umGlobRouting As Long = 67 '+C / access to global /connect's and /squit's
Public Const umCanDie As Long = 68      '+D / access to /die server
Public Const umCanAdd As Long = 69      '+E / can use /add
Public Const umCanChange As Long = 72   '+H / can use /chghost and /chgnick
Public Const umGlobKills As Long = 75   '+K / access to global /kill's
Public Const umNetAdmin As Long = 78    '+N / is Net Admin
Public Const umGlobOper As Long = 79    '+O / Global IRC Operator, flags included: oRDCKN
Public Const umProtected As Long = 80   '+P / protected operator, can't be deopped or kicked from a channel
Public Const umCanRestart As Long = 82  '+R / access to /restart server
Public Const umService As Long = 83     '+S / is a service
Public Const umCanWallop As Long = 87   '+W / can use wallops system
Public Const umRemoteAdmin As Long = 90 '+Z / is a Remote Administrator (Is logged in via /remoteadm login)

'Lower Case

Public Const umCanKline As Long = 98    '+b / Can /kline user
Public Const umLocRouting As Long = 99  '+c / access to local /connect's and /squit's
Public Const umHostCloak As Long = 100  '+d / gets his host cloaked
Public Const umCanRehash As Long = 101  '+e / access to /rehash server
Public Const umInvisible As Long = 105  '+i / invisible, only visible to those who know the exact nick
Public Const umLocKills As Long = 107   '+k / access to local /kill's
Public Const umLocOper As Long = 111    '+o / Local IRC Operator, flags included: eckbB (used to be rhgwlckbBnuf)
Public Const umLProtected As Long = 112 '+p / Lower level protected oper - same as P except it has a different 'strength'
Public Const umRegistered As Long = 114 '+r / has a registered nick
Public Const umServerMsg As Long = 115  '+s / recieves servermessages
Public Const umWallOps As Long = 119    '+w / recieves wallops
Public Const umIRCX As Long = 120       '+x / IRCX user
Public Const umGagged As Long = 122     '+z / is gagged (cannot PRIVMSG or NOTICE)

Public Function TranslateCode$(Code&, Optional Nick$, Optional Chan$, Optional cmd$)
#If Debugging = 1 Then
    SendSvrMsg "TRANSLATECODE called! (" & Nick & ")"
#End If
On Error Resume Next
Select Case Code
  Case ERR_NOSUCHNICK
    TranslateCode = Nick & " :No such nick/channel"
  Case ERR_NOSUCHSERVER
    TranslateCode = Nick & " :No such server"
  Case ERR_NOSUCHCHANNEL
    TranslateCode = Chan & " :No such channel"
  Case ERR_CANNOTSENDTOCHAN
    TranslateCode = Chan & " :Cannot send to channel"
  Case ERR_TOOMANYCHANNELS
    TranslateCode = Chan & " :You have joined too many channels"
  Case ERR_WASNOSUCHNICK
    TranslateCode = Nick & " :There was no such nickname"
  Case ERR_NOSUCHSERVICE
    TranslateCode = Nick & " :No such service"
  Case ERR_NOORIGIN
    TranslateCode = ":No origin specified"
  Case ERR_NORECIPIENT
    TranslateCode = ":No recipient given " & cmd
  Case ERR_NOTEXTTOSEND
    TranslateCode = ":No text to send"
  Case ERR_NOTOPLEVEL
    TranslateCode = Nick & " :No toplevel domain specified"
  Case ERR_WILDTOPLEVEL
    TranslateCode = Nick & " :Wildcard in toplevel domain"
  'Case ERR_BADMASK
  ' TranslateCode = parv(1) & " :Bad Server/host mask"
  Case ERR_UNKNOWNCOMMAND
    TranslateCode = cmd & " :Unknown command"
  Case ERR_NOMOTD
    TranslateCode = ":MOTD File is missing"
  Case ERR_NOADMININFO
    TranslateCode = Nick & " :No administrative info available"
  Case ERR_NONICKNAMEGIVEN
    TranslateCode = ":No nickname given"
  Case ERR_ERRONEUSNICKNAME
    TranslateCode = Nick & " :Erroneous nickname"
  Case ERR_NICKNAMEINUSE
    TranslateCode = Nick & " :Nickname is already in use"
  Case ERR_NICKCOLLISION
    TranslateCode = Nick & " :Nickname collision KILL from " & Chan & "@" & cmd
  Case ERR_BANNICKCHANGE
    TranslateCode = Nick & " :Cannot change nickname while banned on channel"
  Case ERR_USERNOTINCHANNEL
    TranslateCode = Nick & " " & Chan & " :They aren't on that channel"
  Case ERR_NOTONCHANNEL
    TranslateCode = Chan & " :You're not on that channel"
  Case ERR_USERONCHANNEL
    TranslateCode = Nick & " " & Chan & " :is already on channel"
  Case ERR_SUMMONDISABLED
    TranslateCode = ":SUMMON has been disabled"
  Case ERR_USERSDISABLED
    TranslateCode = ":USERS has been disabled"
  Case ERR_NOTREGISTERED
    TranslateCode = ":You have not registered"
  Case ERR_NEEDMOREPARAMS
    TranslateCode = cmd & " :Not enough parameters"
  Case ERR_ALREADYREGISTRED
    TranslateCode = ":Unauthorized command (already registered)"
  Case ERR_NOPERMFORHOST
    TranslateCode = ":Your host isn't among the privileged"
  Case ERR_PASSWDMISMATCH
    TranslateCode = ":Password incorrect"
  Case ERR_YOUREBANNEDCREEP
    TranslateCode = ":You are banned from this server"
  Case ERR_YOUWILLBEBANNED
      TranslateCode = ":You will be banned"
  Case ERR_KEYSET
    TranslateCode = Chan & " :Channel key already set"
  Case ERR_CHANNELISFULL
    TranslateCode = Chan & " :Cannot join channel (+l)"
  Case ERR_UNKNOWNMODE
    TranslateCode = Nick & " :is unknown mode char to me for " & Chan
  Case ERR_INVITEONLYCHAN
    TranslateCode = Chan & " :Cannot join channel (+i)"
  Case ERR_BANNEDFROMCHAN
    TranslateCode = Chan & " :Cannot join channel (+b)"
  Case ERR_BADCHANNELKEY
    TranslateCode = Chan & " :Cannot join channel (+k)"
  Case ERR_BADCHANMASK
    TranslateCode = Chan & " :Bad Channel Mask"
  Case ERR_BANLISTFULL
    TranslateCode = Nick & " " & Chan & " :Channel list is full"
  Case ERR_NOPRIVILEGES
    TranslateCode = ":Permission Denied: You're not an IRC operator"
  Case ERR_CHANOPRIVSNEEDED
    TranslateCode = Chan & " :You're not channel operator"
  Case ERR_CANTKILLSERVER
    TranslateCode = ":You can't kill a server!"
  Case ERR_NOOPERHOST
    TranslateCode = ":No O-lines for your host"
  Case ERR_UMODEUNKNOWNFLAG
    TranslateCode = ":Unknown MODE flag"
  Case ERR_USERSDONTMATCH
    TranslateCode = ":Cannot change mode for other users"
  'IRCX
  Case IRCRPL_PROPEND
    TranslateCode = ":End of properties"
  Case IRCERR_SECURITY
    TranslateCode = ":No permissions to perform command"
  Case IRCERR_BADPROPERTY
    TranslateCode = ":Bad property specified"
  Case IRCERR_BADLEVEL
    TranslateCode = ":Bad level"
  Case IRCERR_BADCOMMAND
    TranslateCode = ":Bad command"
  Case IRCERR_TOOMANYARGUMENTS
    TranslateCode = ":Too many arguments"
  Case IRCERR_ACCESSSECURITY
    TranslateCode = ":Some entires not cleared due to security"
  Case IRCERR_DUPACCESS
    TranslateCode = ":Duplicate access entry"
  Case IRCERR_CHANNELEXIST
    TranslateCode = Chan & " :Channel already exists."
  Case IRCRPL_EVENTADD
    'misusing stuff here, don't even remember.. no translation needed so leave it alone
    TranslateCode = Nick & " " & Chan & " " & cmd
  Case IRCRPL_EVENTDEL
    'misusing stuff here, don't even remember.. no translation needed so leave it alone
    TranslateCode = Nick & " " & Chan & " " & cmd
  Case IRCERR_NOSUCHEVENT
    'and here... nick = nick, chan = event type
    TranslateCode = Nick & " " & Chan & " :No such event type"
  Case IRCERR_EVENTDUP
    'and here.. nick = event, chan = mask
    TranslateCode = Nick & " " & Chan & " :Duplicate event entry"
  Case IRCERR_EVENTMIS
    'and here.. nick = event, chan = mask
    TranslateCode = Nick & " " & Chan & " :Unknown event entry"
  Case IRCERR_BADFUNCTION
    'and here too.. Nick = Command name
    TranslateCode = Nick & " :Bad Function"
  Case IRCRPL_EVENTSTART
    TranslateCode = ":Start of events"
  Case IRCRPL_EVENTEND
    TranslateCode = ":End of events"
  Case RPL_WHOISREGNICK
    TranslateCode = ":is a registered nick"
End Select
End Function
