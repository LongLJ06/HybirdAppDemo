/**
 * Created by czh on 17/8/2.
 */

import { browserHistory } from 'dva/router';

import Conf from './config';

// 埋点要用的参数
const TRACK = ['brand', 'model', 'deviceId', 'systemVersion', 'appVersion', 'device'];

// 用于保存配制title的时候extra里callback的值
// subTitleCallBack[routerName] = callback
const subTitleCallBack = {};


/**
 * 把json字符串转化为json对象
 * 从ios接到我们传过去的数据就直接解析了，我们要的数据就直接被转化为json字符串。ios没法把它转成js 对象
 * 如果用ios的方式转化为对象，只能是{a=3, b=3}之类的，js会报错
 */
function strToJson(str) {
  let obj = {};
  if (typeof (str) === 'object') {
    obj = str;
  } else {
    try {
      obj = JSON.parse(str);
    } catch (err) {
      throw new Error(err);
    }
  }
  return obj;
}

/**
 * 因为ios接收到的匿名函数在他那里就是一串字符串，没法运行加数据
 * 所以需要传给他一个函数名，他在window下运行这个才能把数据传过来
 */

const createWindowFunc = function (fun) {
  xhh.times += 1;
  const funName = `wapGetAppData${xhh.times}`;
  window[funName] = function (d, d2) {
    fun(d, d2);
    // 删除，防止污染全局
    delete window[funName];
  };
  return funName;
};

/**
 * 其它平台调我们的,调用方法 window.Wap.go(xx)
 */
const wap = window.WAP = {
  // 页面内部跳转
  go(obj) {
    browserHistory.push(`/${obj}`);
    // this.vm.$router.push(obj);
  },
  // 更新vm数据 k,v  / {k:v}
  // pushData(k, v) {
  //   const arg = arguments.length;
  //   const self = this;
  //   if (!arg) return;
  //   if (arg === 1) {
  //     Object.keys(k).forEach((item) => {
  //       self._setData(item, k[item]);
  //     });
  //   } else {
  //     self._setData(k, v);
  //   }
  // },
  // // 设置单一数据
  // _setData(k, v) {
  //   // Vue.set(this.vm, k, v);
  // },
  // 接收app的事件
  // 现在一共有goBack: 后退, subTitleEvent:点副标题
  trigger(type, obj) {
    wap[type](obj);
    // ios通过return值确定是wap过来的
    // wap跟bbs/活动/旧交互最大的不同是接管了app返回按钮
    // android无法接收return值，所以他会在putData('title')的时候记录
    if (type === 'goBack' && Conf.device === 1) {
      return true;
    }
  },
  // app加载完时回调
  loaded() {
  },
  // 点击副标题
  // extra: 配制title的时候传过来的值
  subTitleEvent(extra) {
    if (!extra) return;
    const ex = strToJson(extra);
    // 路由跳转
    if (ex.router) {
      wap.go(ex.router);
    }
    // 回调函数, 把当前vm当作this传过去
    if (ex.callback) {
      subTitleCallBack[ex.callback].call(wap.vm);
    }
  },
  // 点回退按钮
  goBack() {
    // 如果是来时的路由则关闭
    if (wap._isBackApp()) {
      xhh.doAction('close');
    } else {
      window.history.back();
    }
  },
  _isBackApp() {
    return true;
    // const vm = wap.vm;
    // const routeName = vm.$route.name;
    // const query = vm.$route.query;
    // 当前页面为第一次进入webview页面
    // return xhh.curRouterName === Conf.fromAppRouter ||
    //   // 我的鑫利宝且加入状态
    //   routeName === 'xlbAccount' && vm.base.join_in_status === 1 ||
    //   // 开通存管，在成功页，如果成功了返回则跳到app帐户页
    //   routeName === 'depositoryResult' && query.state === 1 ||
    //   // 充值页点返回要跳到帐户页
    //   routeName === 'callBackReturn';
  },

};

/**
 * app 调我们的
 */
const xhh = window.XHH = {
  // 当前title参数的配制, 方便当前页面多次配制
  _curTitle: {},
  // 从app获取数据次数
  times: 0,
  // 如果有子路由这边只记录父路由
  curRouterName: '',
  // 将要进到的路由，这个跟curRouterName的区别是
  // 有子路由时上面记录父路由，这个记录子路由
  toName: '',
  conf: {},
  init(self, callback) {
    // var toName = to.name
    // xhh.curRouterName = to.matched[0].name
    // xhh.toName = toName
    // if (!Conf.fromAppRouter) {
    //   //   // 开始配制app数据
    //   xhh.appInit(self, callback);
    //   // xhh.appInitCookie(self, callback);
    //   //   // 赋值
    //   //   isOldMode = !Conf.appNewMode
    //   //   // 记录来时的路由
    //   //   Conf.fromAppRouter = xhh.curRouterName
    // }
    xhh.appInit(self, callback);
    // 注册js事件
    // params 里面包含type，指定数据类型，data是一个json，返回数据的格式。，cb可传可不传。
    // window.sendJS = function (params, callback) {
    //   params = strToJson(params);
    //   self[params.type](params.data);
    //   callback && callback();
    // };
    window.sendJS = function (params, cb) {
      const p = strToJson(params);
      if (p.type === 'updateCookiesCallBack') {
        xhh.appInitCookie(self, cb);
      }
      self[p.type](p.data);
      if (cb) {
        cb();
      }
    };
  },

  // 主要用于多次配制title参数, 如果是字符串则为title值
  /**
   * @param {{isApp:string,isString:function}} data
   */
  setTitle(opts) {
    let options = opts;
    if (!options || !Conf.isApp) return;
    if (Object.isString(options)) {
      options = {
        title: options,
      };
    }
    options = Object.assign({}, xhh._curTitle, options);
    this.putData('title', options);
    this._curTitle = options;
  },
  goback(type) {
    // alert(type);
    if (!type) {
      this.doAction('close', '', () => {
      });
    } else {
      window.history.back();
    }
  },
  // 向app传递数据
  // ios
  putData(type, params) {
    this._unify('putData', type, params);
  },
  // 从app获取参数
  getData(type, params, fun, callback) {
    // 纠正数据类型
    // if (Object.isFunction(params)) {
    //   fun = params
    //   params = null
    // }
    let myfun = fun;
    myfun = createWindowFunc(myfun);

    // let doAction2 = 'getData';
    // window.webkit.messageHandlers[doAction2].postMessage([type, params, fun])
    this._unify('getData', type, params, myfun, callback);
  },
  // 要求app跳到某个页面
  goToNative(pageName, params) {
    // 用于goToNative时与传入值对比，如果一致则要close关闭
    // 用于规避a->b(webview)>a ios/android会打开一个新的a
    if (Conf.fromPage && Conf.fromPage === pageName) {
      this.doAction('close');
    } else {
      const p = params;
      this._unify('goToNative', pageName, p);
    }
  },
  // 泛类，跳转到app除goToNative定义以外的页面
  // 即没提前定义的，这个要wap来区分ios/app
  // Class: app类名
  // isHandleClose: 要不要关闭当前webView(true/false)
  // 以上两个字段是固定的，大小写敏感,必填
  goToExtraNative(params) {
    this._unify('goToExtraNative', null, params);
  },
  // 要求app作交互
  // type有以下几种事件
  // 关闭webview: close
  // 配制分享: share (content, imgUrl, webUrl, title)
  doAction(type, obj, fun) {
    let myfun = fun;
    if (typeof myfun === 'function') {
      myfun = createWindowFunc(myfun);
      return this._unify('doAction', type, obj, myfun);
    }
    this._unify('doAction', type, obj);
  },
  // 统一平台差别
  _unify(postName, activeType, obj, func, callback) {
    // console.info(postName);
    // console.info(activeType);
    // console.info(obj);
    // console.info(func);
    // console.info(callback);
    if (activeType === 'title') {
      const extra = obj.extra || {};
      const cb = extra.callback;
      const routerName = this.toName;
      // 如果有回调函数，则把他加到subTitleCallBack[routerName]
      // 然后再把他的值设置为routerName
      // 这里有个问题，就算是传进来一个titlemap的Object.assign还是会改变原来的值
      // 所有这里要判读cb是不是function,有空再感觉下
      if (cb && typeof cb === 'function') {
        subTitleCallBack[routerName] = cb;
        extra.callback = routerName;
      }
    }

    if (!window.webkit && !window.androidApp) {
      if (callback) {
        callback();
      }
      return;
    }
    if (Conf.device === '1') {
      // 高级交互, 8.0以后
      if (Conf.iosIsHigh) {
        window.webkit.messageHandlers[postName].postMessage([activeType, obj, func]);
      } else {
        window[postName](activeType, obj, func);
      }
      // 下面是anroid
    } else {
      let myObj = obj;
      if (myObj) {
        myObj = JSON.stringify(myObj);
      }
      if (func === undefined) {
        return window.androidApp[postName](activeType, myObj);
      }
      window.androidApp[postName](activeType, myObj, func);
    }
    // window.androidApp.

    // window.androidApp[postName](activeType, obj, func)
    // window[postName](activeType, obj, func)
  },
  // 页面加载完，开始配制app相关数据前
  appInit(self, callback) {
    // 只有新版本才会有这个
    // if (!Conf.appNewMode) return
    // 新交互url没 brand/model/deviceID 三个字段要加上, 现在主要用于埋点
    // ios低级版本只有页面下载完成才会把相关交互事件加到webView
    // 所以这时在track bind的时候再运行一次就好
    this.getData('appData', '', (d) => {
      // alert(d);
      const myD = strToJson(d);
      TRACK.forEach((k) => {
        Conf[k] = myD[k];
      });
      this.conf = Conf;
      const osVersion = Conf.systemVersion;
      const appVersion = Conf.appVersion;
      const deviceType = Conf.brand;
      localStorage.setItem('osVersion', osVersion);
      localStorage.setItem('appVersion', appVersion);
      localStorage.setItem('deviceType', deviceType);
      // Vue.http.headers.common['os-version'] = Conf.systemVersion;
      // alert(Conf.systemVersion);
      // Vue.http.headers.common['os-version'] = 'android6.0.1';

      // this.getData('appCookie', '', function (data) {
      //   data = strToJson(data);
      //   for(var i in data){
      //     this.$cookie.set(i, data[i]);
      //   }
      // })
      //
      // callback && callback();
    }, callback);
    this.putData('setWebControlBack', {
      isWebControlBack: true,
    });
    this.appInitCookie(self, callback);
  },

  appInitCookie(self, callback) {
    if (Conf.device === '1') {
      let myData = '';
      this.getData('appCookie', '', (data) => {
        myData = strToJson(data);
        // let uniqueCookie;
        // for (const i in myData) {
        //   // self.$cookie.set(i, myData[i]);
        //   uniqueCookie[i] = myData[i];
        // }
        let vars;
        for (const key in myData) {
          if (key) {
            vars = `${key}=${encodeURIComponent(myData[key])}`;
            document.cookie = vars;
          }
        }
        if (data && callback) {
          callback();
        }
      });
    } else {
      this.getData('appCookie', '', (data) => {
        const myData = strToJson(data);
        let vars;
        myData.forEach((v) => {
          vars = `${v.name}=${encodeURIComponent(v.value)}`;
          document.cookie = vars;
          // self.$cookie.set(v.name, v.value);
        });
        if (data && callback) {
          callback();
        }
      });
    }
    // setTimeout(() => {
    //   if (callback) {
    //     callback();
    //   }
    // }, 1000);
  },
  toJSON(data) {
    return strToJson(data);
  },
  analysis(params) {
    this.putData('Umeng', {
      type: params.type || 'click',
      dataAnalysis: params.dataAnalysis,
      property: params.property || '',
    });
  },
};

export {
  xhh,
  wap,
};
