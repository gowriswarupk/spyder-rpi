#!/usr/bin/env python3

import os
import subprocess
import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging

cred = credentials.Certificate("/home/kali/Documents/spyderapp1-firebase-adminsdk-fyqib-c2df0c7ed3.json")
firebase_admin.initialize_app(cred)


def send_push_notification(title, body, token):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
    )
    response = messaging.send(message)
    print(f"Notification sent: {response}")



def handle_remote_message(message):
    script_name = message.data.get("scriptname")
    if script_name:
        script_path = os.path.join("/home/kali/Desktop/confirmed_use_scripts/scripts/", script_name)
        if os.path.isfile(script_path):
            subprocess.call(["sudo","python3", script_path])
            send_push_notification("Task Completed", f"{script_name} has been executed.", message.sender_token)
        else:
            print(f"Script not found: {script_name}")
    else:
        print("No scriptname provided in the message")

def main():
    while True:
        message = messaging.receive_message()
        if message:
            handle_remote_message(message)

if __name__ == "__main__":
    main()

