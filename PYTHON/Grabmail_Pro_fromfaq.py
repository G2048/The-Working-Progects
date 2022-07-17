import argparse
import imaplib
import sys

from getpass import getpass


def log(msg):
    sys.stdout.write('%s\n' % msg)


# START
parser = argparse.ArgumentParser(
    description='Grab mail from IMAP by uid.',
    epilog='Use for to debug errors of mailgrabber only'
)
parser.add_argument('--server', required=True)
parser.add_argument('--login', required=True)
parser.add_argument('--password', default=None)
parser.add_argument('--port', default=993, type=int)
parser.add_argument('--uid', required=True)

# Parse cmdline arguments
args = parser.parse_args()
if args.password is None:
    args.password = getpass()

# Select connection class
if args.port == 143:
    connection_class = imaplib.IMAP4
else:
    connection_class = imaplib.IMAP4_SSL



try:
    log('Connect to %s:%s' % (args.server, args.port))
    conn = connection_class(args.server, args.port)
    log('Authenticate with login %s' % args.login)
    conn.login(args.login, args.password)
    log('Select Inbox')
    status, resp = conn.select('Inbox')
    log(status)
    if status != 'OK':
        raise connection_class.error(resp)
    log('Trying to fetch mail with uid: %s' % args.uid)
    status, resp = conn.uid('fetch', args.uid, '(RFC822)')
    if status != 'OK':
        raise connection_class.error(resp)
    if resp and resp[0] is None:
        msg = 'Mail with uid %s does not exist' % args.uid
        raise connection_class.error(msg)
except connection_class.error as e:
    log('Error: %s' % e)
else:
    log(status)
    fname = 'MailUID%s.eml' % args.uid
    log('Saving mail to file: %s' % fname)
    try:
        # print resp[0]
        with open(fname, 'wb') as f:
            f.write(resp[0][1])
    except Exception as e:
        log(e)
finally:
    log('Close \'Inbox\' and logout...')
    try:
        conn.close()
    except connection_class.error:
        pass
    status, _ = conn.logout()
    log(status)
