using HTTP, Gumbo, AbstractTrees
api_url = "https://explorecourses.stanford.edu/search?view=catalog&academicYear=&page=0&q=ACCT&filter-departmentcode-ACCT=on&filter-coursestatus-Active=on&filter-term-Summer=on"
r = HTTP.request("GET", api_url)
body_string = String(r.body)
open("file.html","w") do file
    write(file,body_string)
end
split(String(body_string), '\n')
doc = parsehtml(body_string)
names(Gumbo)
search_results = doc.root[2][2][3][1]
list_of_courses = 0
search_results.children[1].children
for search_result in search_results.children
    if attrs(search_result)["class"] == "searchResult" || attrs(search_result)["class"] == "searchResult-noBorder" 
        list_of_courses += 1
        println(length(search_result.children))
        index = findall(x->x=="div", String.(tag.(search_result.children)))   
        println(search_result.children[index][1][1][1][1])
    end
end
print("Number of courses :", list_of_courses)