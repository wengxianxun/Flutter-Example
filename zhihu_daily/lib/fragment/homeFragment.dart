import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:zhihu_daily/model/story.dart';
import 'package:zhihu_daily/constants/urls.dart';
import 'package:zhihu_daily/widgets/homeBanner.dart';
import 'package:zhihu_daily/utils/timeUtil.dart';

class HomeFragment extends StatefulWidget {

  HomeFragment({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FragmentState();
  }
}

class _FragmentState extends State<HomeFragment> {
  bool showLoading;
  List<StoryModel> bannerStories = [];
  LinkedHashMap<String, List<StoryModel>> storiesOfDate = LinkedHashMap();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (showLoading) {
      body = Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: EdgeInsets.only(),
        children: _buildHomeList(context),
      );
    }
    return body;
  }

  List<Widget> _buildHomeList(BuildContext context) {
    List<Widget> list = [];
    if (bannerStories.length > 0) {
      list.add(HomeBanner(bannerStories));
    }
    if (storiesOfDate.length > 0) {
      storiesOfDate.forEach((date, storiesList) {
        list.add(_buildDateItem(date));
        storiesList.forEach((story) {
          list.add(_buildStoryItem(story));
        });
      });
    }
    return list;
  }

  Widget _buildDateItem(String date) {
    DateTime time = DateTime.parse(date);
    if (sameDay(time, DateTime.now())) {
      date = '今日热闻';
    } else {
      date = formatTime(time);
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      child: Text(
          date, style: TextStyle(fontSize: 14.0, color: Colors.grey[700])),
    );
  }

  Widget _buildStoryItem(StoryModel story) {
    return Container(
      padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 3.0),
      child: Card(
        child: Container(
          padding: EdgeInsets.all(10.0),
          child: Row(children: <Widget>[
            Expanded(child: Text(story.title,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500))),
            Container(
              width: 80.0,
              height: 80.0,
              margin: EdgeInsets.only(left: 10.0),
              child: Image.network(story.image),
            )
          ],),
        ),
      ),
    );
  }

  _loadData() {
    setState(() {
      showLoading = true;
    });
    _refreshData();
  }

  _refreshData() async {
    String url = Urls.NEWS_LAST;
    Response response = await get(url);
    if (response.statusCode == 200) {
      Map<String, dynamic> result = json.decode(response.body);
      if (result['top_stories'] != null) {
        bannerStories.clear();
        result['top_stories'].forEach((item) {
          bannerStories.add(StoryModel.fromJson(item));
        });
      }
      if (result['date'] != null) {
        List<StoryModel> models = [];
        if (result['stories'] != null) {
          result['stories'].forEach((item) =>
              models.add(StoryModel.fromJson(item)));
        }
        storiesOfDate.update(
            result['date'], (old) => models, ifAbsent: () => models);
      }
    }

    setState(() {
      showLoading = false;
    });
  }

  _loadMore() async {
    String url = Urls.NEWS_BEFORE + storiesOfDate.keys.last;
    Response response = await get(url);
    if (response.statusCode == 200) {
      Map<String, dynamic> result = json.decode(response.body);
      if (result['date'] != null) {
        List<StoryModel> models = [];
        if (result['stories'] != null) {
          result['stories'].forEach((item) =>
              models.add(StoryModel.fromJson(item)));
        }
        storiesOfDate.putIfAbsent(result['date'], () => models);
      }
    }
    setState(() {});
  }
}