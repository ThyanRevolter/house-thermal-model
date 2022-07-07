import requests
api_url = r"https://explorecourses.stanford.edu/search?view=catalog&academicYear=&page=0&q=ACCT&filter-departmentcode-ACCT=on&filter-coursestatus-Active=on&filter-term-Summer=on"
page = requests.get(api_url)
print(page.text)