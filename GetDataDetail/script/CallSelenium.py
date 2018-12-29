#!/usr/bin/python
# coding : utf-8

import sys
import warnings
from selenium import webdriver

warnings.filterwarnings("ignore")
url = sys.argv[1]

service_args = [
    '--proxy=192.168.1.20:3128',
    '--proxy-type = https',
    '--load-images = no',
    '--disk-cache = yes',
    '--ignore-ssl-errors = true'
]

driver = webdriver.PhantomJS(executable_path = '/Users/iyoyo/Desktop/phantomjs-2.1.1-macosx/bin/phantomjs', service_args = service_args)
driver.get(url)

text = driver.find_element_by_xpath("//*[@class='py-1 px-3 text-sm cursor-pointer Link block uppercase']").get_attribute('href')
video = driver.find_element_by_xpath("//*[@class='py-1 px-3 text-sm cursor-pointer Link block']").get_attribute('href')

print(text + ':' + video)

driver.quit()
