#!/bin/bash
sudo pkill gunicorn
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart supervisord
