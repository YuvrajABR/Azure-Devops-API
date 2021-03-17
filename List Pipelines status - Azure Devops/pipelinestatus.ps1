$personalToken = ""  #  https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page
$organization = "" # azure devops organization 
$project = ""
$path = "$($HOME)\pipelines.csv"


$token  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($personalToken)"))
$header = @{authorization = "Basic $token"}

#get list all the pipelines 

$result = Invoke-RestMethod "https://$($organization).visualstudio.com/$($project)/_apis/pipelines?api-version=6.0-preview.1" -Method Get -ContentType "application/json" -Headers $header
$relDefs = $result.value

add-content -Path $path -Value '"Folder","Name","PipelinURL","Total Runs","Success","Failed","Canceled"'
if($relDefs.count -gt 0){
    Write-Host "$project $($relDefs.count) release def founds" -ForegroundColor Blue
    $relDefs | ForEach-Object {
        $folder = $_.Folder 
        $name = $_.Name
		
		#creating a pipeline url, not available in the output.
        $pipelineurl = "https://$($organization).visualstudio.com/$($project)/_build?definitionId=$($_.Id)"
       
		# get all the runs for each pipeline.
        $response = Invoke-RestMethod "https://$($organization).visualstudio.com/$($project)/_apis/pipelines/$($_.Id)/runs" -Method Get -ContentType "application/json" -Headers $header
       # Write-Host ($response.value.result)

		# getting coount of success, failure and canceled pipelines.
        $success = ($response.value.result | Where-Object {$_ -eq "succeeded"}).count
        $failed = ($response.value.result | Where-Object {$_ -eq "failed"}).count
        $cancel = ($response.value.result | Where-Object {$_ -eq "canceled"}).count

        $result  = $folder + "," + $name + "," + $pipelineurl + "," + $($response.count) + "," + $success + "," + $failed + "," + $cancel
        Write-Host $result
        $success = 0
        $failed = 0
        $cancel = 0
		
		# wrting data to the csv file.
        $result | add-content -Path $path
    }
}
