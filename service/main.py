#    Copyright 2022 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

from flask import abort
from google.cloud.logging_v2 import Client, Logger
import functions_framework
import os
import base64
import json

@functions_framework.http
def proxy_log_entry(request):
    if request.method == 'POST':

        # Get destination
        project_id = os.environ.get('TARGET_PROJECT_ID')
        if not project_id:
            import logging
            logging.error(RuntimeError('TARGET_PROJECT_ID environment variable not found'))
            return abort(500)

        # Create the client and the logger
        client = Client(project=project_id)
        logger_name = os.environ.get('LOGGER_NAME')
        logger = Logger(logger_name, client)

        # get the logs entry data and write
        pubsub_message = request.get_json(silent=True)
        log_message = json.loads(base64.b64decode(
            pubsub_message['message']['data']))

        logger.log_struct(
            log_message,
            # resource=Resource(type="log_forwarder", labels={}),
            severity=log_message['severity']
        )

        return {'result': 'ok'}
    else:
        return abort(405)
