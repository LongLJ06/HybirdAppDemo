import React from 'react';
// import PropTypes from 'prop-types';
import { connect } from 'dva';
import { Link } from 'dva/router';
import { Toast, List } from 'antd-mobile';
import { wap, xhh } from 'utils/native/interaction';

import request from 'utils/request';

const Item = List.Item;
class ListJsbridge extends React.Component {
  componentWillMount() {
    // 页面初始化 title右上角添加phone图标    
    xhh.putData('addRightNavigationBarItem', {
      data: {
        // isHidden: false,// false或者不传默认显示
        type: 'telephone',
      },
    }); // 在title的右边添加电话图标
  }

  componentDidMount() {
    xhh.init(this, this.testRequest);
    xhh.doAction(
      'showOrDismissTipMessage',
      {
        status: 'update',
        data: {
          isShow: false,
          flag: 0, // 0:loading; 1:toast
          customMessage: '加载中…',
          canManualHide: false, // true:蒙版在页面；false:蒙版在屏幕
        },
      });
  }

  // 从app中拿到参数
  getData() {
    console.info('getData');
    xhh.getData('appData', { test: 1 }, (data) => {
      alert('调用native success');
    });
  }

  // 拿到cookies
  getCookies() {
    xhh.getData('appCookie', { test: 1 }, (data) => {
      alert('调用native success');
    });
  }

  // 向app传数据
  setTitle() {
    xhh.putData('setTitle', { title: 'H5交互' });
  }

  // addRightNavigationBarItem() {
  // }

  // 获取当前时间 年-月-日
  getNowFormatDate() {
    const date = new Date();
    const seperator1 = '-';
    let month = date.getMonth() + 1;
    let strDate = date.getDate();
    if (month >= 1 && month <= 9) {
      month = `0${month}`;
    }
    if (strDate >= 0 && strDate <= 9) {
      strDate = `0${strDate}`;
    }
    const currentdate = date.getFullYear() + seperator1 + month + seperator1 + strDate;
    return currentdate;
  }

  // 选择多少个月（12，24，36）
  showActionSheet() {
    xhh.doAction('showActionSheet', { items: [{ ID: '', name: '' }, { ID: '', name: '' }] });
  }

  // showActionSheet() {
  //   xhh.doAction('showActionSheet', {
  //     status: 'update',
  //     data: {
  //       // 没有title的时候，传入空字符串。
  //       title: '',
  //       selectedName: '银行还款',
  //       selectedId: '11',
  //       items: [{ name: '银行还款', ID: '11' }, { name: '票据贴现', ID: '12312' }, { name: '保证金退还', ID: '2311' }, { name: '股票质押', ID: '1231' }],
  //     },
  //   }, (data) => {
  //     alert(data);
  //   });
  // }

  testRequest() {
    // alert('testRequest');
  }

  // 地区插件调用
  chooseArea() {
    xhh.doAction('showAreaPicker', {
      status: 'update',
      data: {
        provinceName: '浙江省',
        provinceCode: '330000',
        cityName: '杭州市',
        cityCode: '330100',
        areaName: '拱墅区',
        areaCode: '330105',
      },
    }, (data) => {
      const myData = xhh.toJSON(data);
    });
  }

  // 时间插件
  chooseTime() {
    // currentTime 选中的时间
    // type 自定义属性
    // startTime 可选择的最早时间
    // endTime 可选择的最晚时间
    // (data) => {} 选择以后的回调函数
    xhh.doAction('showDatePicker', { status: 'update', data: { currentTime: '2017-01-01', type: 'xxx', startTime: '2015-01-01', endTime: '2018-01-01' } }, (data) => {
      alert('调用native success');
    });
  }

  goToBankView() {
    // app 跳到某个页面
    xhh.goToNative('goToBankView', {
      status: 'update',
      data: {
        bankName: '建设银行',
        bankNo: '34234',
        BranchName: '杭州分行',
        BranchNo: '2312',
      },
    });
  }

  // 授信批复
  goToCreditApprovalView() {
    xhh.goToNative('goToCreditApprovalView', {
      status: 'update',
      data: {
        createTime: '2017-07-12',
        validTime: '7',
      },
    });
  }

  // 授信批复的回调函数
  goToCreditApprovalViewCallBack(data) {
    alert(data.createTime);
    alert(data.validTime);
  }

  goToFileUpdateView() {
    xhh.goToNative('goToFileUpdateView', {
      status: 'update', data: {},
    });
  }

  // 添加抵押物
  goToGuaranteeView() {
    xhh.goToNative('goToGuaranteeView', {
      status: 'update',
      data: {
        addressArr: [{
          provinceName: '浙江省',
          provinceCode: '330000',
          cityName: '杭州市',
          cityCode: '330100',
          areaName: '拱墅区',
          areaCode: '330105',
          detailAddress: '拱墅区111',
          certificateComplete: true,
        }, {
          provinceName: '浙江省',
          provinceCode: '330000',
          cityName: '杭州市',
          cityCode: '330100',
          areaName: '拱墅区',
          areaCode: '330105',
          detailAddress: '拱墅区11112',
          certificateComplete: false,
        }],

      },
    });
  }

  smallRequest() {
    alert('fuck');
    return request('/cas/getLoginUser.jhtml', {
      method: 'POST',
    });
  }

  chooseStartDate() {
    // 2017-01-01
    xhh.doAction('showDatePicker', { status: 'update', data: { currentTime: this.getNowFormatDate(), type: 'startTime', endTime: '2018-01-01' } }, (data) => {
      alert(data);
    });
  }

  chooseEndDate() {
    xhh.doAction('showDatePicker', { status: 'update', data: { currentTime: this.getNowFormatDate(), startTime: '2017-01-01', type: 'endTime' } }, (data) => {
      alert(data);
    });
  }

  toNativeIos() {
    xhh.goToNative('goToTestViewController', { view: 'XZCSupervisorySystemViewController' }, (data) => {
      alert('调用native success');
      alert(data);
    });
  }

  toNativeAndroid() {
    xhh.goToNative('goToLoginView', { title: '登录页面', isFirstIn: true, username: 'TOM' }, (data) => {
      alert('调用native success');
      alert(data);
    });
  }

  // 选择借款人
  goToBorrowerListView() {
    // data 初始化的时候要传 {}，
    xhh.goToNative('goToBorrowerListView', {
      type: '',
      data: {},
    });
  }

  // 添加借款人
  toAddBorrower() {
    // (data) => {} 添加借款人后的回调函数
    xhh.goToNative('goToAddBorrowerView', {}, (data) => {
      alert('添加借款人');
    });
  }

  // 添加抵押物的回调函数
  goToGuaranteeViewCallBack(data) {
    alert(data.addressArr);
  }

  routerPush() {
    // wap.goBack();
    wap.go('AssignmentAudit');
  }

  // 根据从后端请求到的code值，弹出对应的提示框
  dealRequestCompleteCode() {
    xhh.putData('dealRequestCompleteCode', {
      code: '123',
      message: 'abc',
    });
  }

  /**
   * 相应的原生回调
   * */

  goToBankViewCallBack(data) {
    alert(data.bankName);
  }

  goToFileUpdateViewCallBack(data) {
    alert('goToFileUpdateViewCallBack 调用成功');
    alert(data);
  }

  goBackCallBack(data) {
    Toast.loading('Loading...', 1, () => {
      alert(data);
      xhh.goback(0);
    });
  }

  render() {
    return (<div>
      <List renderHeader={() => '交互页面测试'} className="my-list">
        <Item arrow="horizontal" platform="ios" onClick={this.routerPush}>测试routerPush</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.getData}>获取appData</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.getCookies}>获取cookies</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.toNativeIos}>Tonative 方法去ios</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.toNativeAndroid}>Tonative 方法去android</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.setTitle}>改变title</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.chooseArea}>chooseArea 插件调用</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.chooseTime}>时间插件</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.showActionSheet}>showActionSheet插件</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.goToBankView}>银行native页面</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.goToCreditApprovalView}>授信批复插件</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.goToGuaranteeView}>抵押款下款插件</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.goToFileUpdateView}>上传资料插件</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.smallRequest}>做个小请求，验证cookies</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.chooseStartDate}>choose_startDate</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.chooseEndDate}>choose_endDate</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.goToBorrowerListView}>选择借款人</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.toAddBorrower}>添加借款人</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.goToGuaranteeView}>添加抵押物</Item>
        <Item arrow="horizontal" platform="ios" onClick={this.dealRequestCompleteCode}>根据code弹出对应提示</Item>
      </List>
      <List renderHeader={() => '业务页面跳转'} className="my-list">
        <Link to="/Project?pane=1&id=1abc8670-db8b-e711-80dd-0050569572da"><Item arrow="horizontal">项目详情/审批——开发用（数据全，需要105账号支持）</Item></Link>
        <Link to="AssignmentAudit"><Item arrow="horizontal">详情/审批</Item></Link>
      </List>
    </div>)
    ;
  }
}

function Jsbridge() {
  return (
    <ListJsbridge />
  );
}
//
// Jsbridge.propTypes = {
//   location: PropTypes.object,
// };
//
// Jsbridge.defaultProps = {
//   location: '',
// };

function mapStateToProps() {
  return {};
}

export default connect(mapStateToProps)(Jsbridge);
