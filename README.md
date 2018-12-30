# CrawlDataProject
***使用perl脚本爬取网上数据***

## 一.获取待爬取的URL列表

### 1.用法：
- perl GetCrawlDataList.pl

### 2.输入：
- a.依据待爬去的网站，配置解析DOM代码；

### 3.输出：
- a.自定义格式，建议为URL文件列表；

## 二、解析URL获取目标数据

### 1.用法：
- perl MultiCrawlDataFromWeb.pl input threadnum

### 2.输入：
- a.【步骤一】的输出结果；
- b. 新增解析Dom的子函数；
- c. 并发线程数；
- d. 配置科学上网代理池，见config/config.ini

### 3.输出：
- a.格式为json的结果文件，详细如下：
```
{
  "filename" : "",     #wavname
  "url": "",           #url
  "info": "",          #text
  "time": ""           #timestampt
}

```
