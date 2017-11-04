# Quick Start
- Create a schedule task to run *Invoke-Script.ps1* every minute to execute other scripts.
- Test-RunInterval is used to control the actual execution interval of scripts.
- https://nxlog.co/products/nxlog-community-edition/download.

# Process
1. Powershell retrieves a list of computers from AD (or a text file).
2. Get software or process info from remote computers.
3. Add additional info.
4. Convert data to JSON and write to local file.
5. nxlog picks up data from local folder and send to Logstash.
6. Logstash does further processing and indexes to Elasticsearch.
