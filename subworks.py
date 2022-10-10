# -*-coding:utf-8-*-

import json
import os
import sqlite3
from flask import Flask, request, session, g, redirect, url_for, abort, \
     render_template, flash
from config import devcfg
import re
from dingTalk import sendmsg

import logging

from tornado.wsgi import WSGIContainer
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

define('port', type=int, default=8111)
# deploy or debug
define('mode', default='debug')
import cat


import sys
# reload(sys)
# sys.setdefaultencoding('utf-8')

app = Flask(__name__)
app.config.from_object(devcfg)



@app.before_request
def before_request():
    g.db = connect_db()

def connect_db():
    """Connects to the specific database."""

    rv = sqlite3.connect(app.config['DATABASE'])

    rv.row_factory = sqlite3.Row
    return rv

def get_db():
    """Opens a new database connection if there is none yet for the
    current application context.
    """
    if not hasattr(g, 'sqlite_db'):
        g.sqlite_db = connect_db()
    return g.sqlite_db

def init_db():
    print(app.config['DATABASE'])
    with app.app_context():
        db = get_db()
        with app.open_resource('schema.sql', mode='r') as f:
            db.cursor().executescript(f.read())
        db.commit()

def publish(string, is_restart):
    if is_restart == 'publish':
        os.system("sh ./subwork_publish.sh " + string)
    elif is_restart == 'on':
        os.system("sh ./subworks_restart_app.sh " + string)
    text = os.popen("cat log.txt | grep error").read()
    flag = re.match(r'.*?error.*?', text)
    ret_text = os.popen("tail -n 1 log.txt").read()
    print(ret_text[20:])
    # pub_content = re.match(r'HEAD 目前位于 8863f39... (.*?)', ret_text)

    # print(pub_content)
    print("flag: " + str(flag))
    if flag is None:
        return True, ret_text[28:]
    else:
        return False, ret_text


@app.route('/')
def show_entries():
    cur = g.db.execute('select pub_date, git,run_name,apps_name,tag,env,server,port from fl_pub order by id desc limit 30;')
    entries = [dict(pub_date=row[0], git=row[1], run_name=row[2], apps_name=row[3], tag=row[4], env=row[5], server=row[6], port=row[7]) for row in cur.fetchall()]
    # print(entries)
    selects = ["menu-soa", "device-soa", "promotion-soa", "fanlai-member-web", "user-center-soa",
               "operation_soa", "partner-soa", "device-router", "promotion-soa", "fanlai-batch", "fanlai-mall-web",
               "fanlai-device-web", "fanlai-sapp-web", "fanlai-manager"]
    return render_template('show_entries.html', entries=entries, selects=selects)

@app.route('/add', methods=['GET', 'POST'])
def add_entry():
    if not session.get('logged_in'):
        abort(401)
    # print(request.form['git'])

    pub_date = request.form['pub_date']
    git = request.form['git']
    apps_name = request.form['apps_name']
    tag = request.form['tag']
    env = request.form['env']
    server = request.form['server']
    run_name = request.form['run_name']
    port = request.form['port']
    restart = request.form.get('restart') or 'publish'
    print("action: "+restart)
    env_url = ''
    if env == 'qa':
        env_url = 'web.sh.fanlai.com'
    elif env == 'rd':
        env_url = 'qa.sh.fanlai.com'

    if port == 0:
        p_string = git + " " + run_name + " " + apps_name + " " + tag + " " + env + " " + server
    else:
        p_string = git + " " + run_name + " " + apps_name + " " + tag + " " + env + " " + server + " " + port
    if session.get('userType') == 0:
        flag, ret_text = publish(p_string, restart)
    else:
        flash(u'无权限，请联系管理员')
        return redirect(url_for('show_entries'))
    # if (flag is True) and (restart == 'on'):
    #     flash(u'重启完成')
    if (flag is True) and (restart == 'publish'):
        g.db.execute('insert into fl_pub (pub_date, git,apps_name,run_name,tag,env,server,port) values (?,?,?,?,?,?,?,?)',[pub_date, git, apps_name, run_name, tag, env, server, port])
        g.db.commit()
        if env != 'online':
            sendmsg(env_url + u"环境发布内容："+run_name+" "+tag+"\n"+u"发布内容："+ret_text)
            flash(u'发布成功')
        else:
            flash(u'online环境打包完成')
    elif (flag is True) and (restart == 'on'):
        # sendmsg(u'重启完成')
        flash(u'重启完成')
        # flash(u'发布失败，tag不对')
    else:
        sendmsg(u'发布失败，tag不对')
        flash(u'发布失败，tag不对')

    return redirect(url_for('show_entries'))

@app.route('/query', methods=['GET', 'POST'])
def query():
    if not session.get('logged_in'):
        print ("not login")
        abort(401)
    run_name = request.values.get('run_name')
    env = request.values.get('env')
    cur = g.db.execute('select pub_date, git,run_name,apps_name,tag,env,server,port from fl_pub where run_name like "%'+run_name+'%" and env="'+env+'" order by id desc limit 1;')
    rsp = [dict(pub_date=row[0], git=row[1], run_name=row[2], apps_name=row[3], tag=row[4], env=row[5], server=row[6], port=row[7]) for row in cur.fetchall()]
    return json.dumps(rsp, ensure_ascii=False)

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if (username == '') or (password == ''):
            error = u'用户名或密码不能为空'
            return render_template('login.html', error=error)
        cur = g.db.execute('select * from userinfo where username=?;', [username])
        # print(cur.fetchall())
        for row in cur.fetchall():
            print(row)
            if request.form['username'] != row[0]:
                error = 'Invalid username'
            elif request.form['password'] != row[1]:
                error = 'Invalid password'
            else:
                session['logged_in'] = True
                session['userType'] = row[2]
                session['username'] = row[0]
                print(session['userType'])
                flash('You were logged in')
                return redirect(url_for('show_entries'))
    # if request.method == 'POST':
    #     if request.form['username'] != app.config['USERNAME']:
    #         error = 'Invalid username'
    #     elif request.form['password'] != app.config['PASSWORD']:
    #         error = 'Invalid password'
    #     else:
    #         session['logged_in'] = True
    #         flash('You were logged in')
    #         return redirect(url_for('show_entries'))
    return render_template('login.html', error=error)

@app.route('/logout')
def logout():
    with cat.Transaction('Transaction', 'logout') as t:
        cat.log_event('sub event', 'logout event')
        try:
            session.pop('logged_in', None)
            session.pop('userType', None)
            session.pop('username', None)
            flash('You were logged out')
            return redirect(url_for('show_entries'))
        except Exception:
            t.set_status(cat.CAT_ERROR)
        t.add_data('context sub')


def main():
    cat.init("subworks", debug=True)
    options.parse_command_line()
    http_server = HTTPServer(WSGIContainer(app))
    http_server.listen(options.port)
    logging.warn("[UOP] App is running on: localhost:%d", options.port)
    IOLoop.instance().start()

if __name__ == '__main__':
    main()
    # app.run(host='0.0.0.0', port=8111)
