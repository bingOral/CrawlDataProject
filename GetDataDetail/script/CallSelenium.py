#!/usr/bin/python
# coding : utf-8

import sys
import warnings
from selenium import webdriver

warnings.filterwarnings("ignore")
url = sys.argv[1]

driver = webdriver.PhantomJS(executable_path = '/home/yankt/work/git/CrawlDataProject/GetDataDetail/data/phantomjs-2.1.1-linux-x86_64/bin/phantomjs')
proxy = webdriver.Proxy()
proxy.http_proxy='192.168.1.20:3128'
proxy.add_to_capabilities(webdriver.DesiredCapabilities.PHANTOMJS)
driver.start_session(webdriver.DesiredCapabilities.PHANTOMJS)
driver.get(url)

try:
	text = driver.find_element_by_xpath("//*[@class='py-1 px-3 text-sm cursor-pointer Link block uppercase']").get_attribute('href')
	video = driver.find_element_by_xpath("//*[@class='py-1 px-3 text-sm cursor-pointer Link block']").get_attribute('href')
	print(text + '@' + video)
except:
	pass

driver.quit()
