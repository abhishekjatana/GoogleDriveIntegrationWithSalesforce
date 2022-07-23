import { LightningElement,track } from 'lwc';
import createAuthenticationURL from '@salesforce/apex/GoogleAuthecation.createAuthenticationURL';
import getaccessTokenorRefreshToken from '@salesforce/apex/GoogleAuthecation.getaccessTokenorRefreshToken';
// import getAccessToken from '@salesforce/apex/GoogleAuthecation.getAccessToken';
import uploadFile from '@salesforce/apex/GoogleAuthecation.uploadFile';
import createContentVersion from '@salesforce/apex/GoogleAuthecation.createContentVersion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class GoogleDriveWithSalesforce extends LightningElement {
@track showdata;
@track beforeAuth=true;
@track afterAuth=false;
@track openListView=true;
@track openGridView=false;
@track accesstoken;
@track fileData;
@track cvId;
@track isSpinner;
@track columns = [
    // { label: 'Id', fieldName: 'id' },
    { label: 'Name', fieldName: 'title' },
    {label: 'Type', fieldName: 'mimeType'},
    { label: 'View Link', fieldName: 'alternateLink' ,  type: 'button', typeAttributes: {
            label: 'View',
            name: 'View',
            title: 'View',
            recordId: { fieldName: 'id' },
            disabled: false,
            variant: 'brand',
            iconPosition: 'left',
        } },
        { label: 'Download Link', fieldName: 'alternateLink' ,  type: 'button', typeAttributes: {
            label: 'Download',
            name: 'Download',
            title: 'Download',
            recordId: { fieldName: 'id' },
            disabled: false,
            value: 'alternateLink',
            variant: 'brand',
            iconPosition: 'left',
            target:'alternateLink'
        } },
    // { label: 'Balance', fieldName: 'amount', type: 'currency' },
    // {type: “button”, typeAttributes: {
    //     label: ‘View’,
    //     name: ‘View’,
    //     title: ‘View’,
    //     disabled: false,
    //     value: ‘view’,
    //     iconPosition: ‘left’
    // }}
    // type: 'button', typeAttributes: {
    //     label: 'View',
    //     name: 'View',
    //     title: 'View',
    //     disabled: false,
    //     value: 'view',
    //     iconPosition: 'left'
    // } },
    // { label: 'CloseAt', fieldName: 'closeAt', type: 'date' },
];

    connectedCallback() {
        try{
            const urlParams = new URLSearchParams(window.location.search);
            const code = urlParams.get('code');
            console.log("url==>",code);
            if(code){
                
                getaccessTokenorRefreshToken({code : code}).then(data=>{
                    // console.log(data);
                    if(data){
                        console.log(typeof data);
                       

                        // let use;
                        // use=data.data;
                        // console.log("data",JSON.stringify(data));
                        // console.log("use",use);
                        // use=JSON.parse(data);
                        // // console.log(JSON.stringify(data));
                        // console.log(JSON.parse(JSON.stringify(data)));
                        this.accesstoken=data.token;
                        console.log("this.accesstoken",this.accesstoken);
                        let reponseData = data.data;
                        // console.log("reponseData",reponseData);
                        if(reponseData){
                            // const currentURL=window.location.href;
                            // console.log("currentURL",currentURL);
                            // window.history.pushState({}, '', currentURL);
                            this.beforeAuth=false;
                            this.afterAuth=true;
                            let parsedreponseData = JSON.parse(reponseData);
                            console.log("parsedreponseData",parsedreponseData);
                            this.showdata = parsedreponseData.items;
                        }
                        if(this.showdata){
                            // console.log('this.showdata',this.showdata);
                           
                        }
                        console.log("showdata",this.showdata);
                       
                    } 
                    // else{
                    //     let url='https://demolivelaunch-developer-edition.ap27.force.com/GoogleIntegration/s';
                    //     window.history.pushState({}, '', url);
                    //     this.beforeAuth=true;
                    //     this.afterAuth=false;

                    // }
                    
                    // if(showdata){

                    // }

                })
            }
        }
        catch(e){
            console.log(e);
        }
          
    }
    handleBack(){
        let url='https://demolivelaunch-developer-edition.ap27.force.com/GoogleIntegration/s';
        window.history.pushState({}, '', url);

        this.beforeAuth=true;
        this.afterAuth=false;
    }
    authorizeGoogle(){
        try{
            createAuthenticationURL().then(data=>{
                console.log("Data",data);
                window.location.href = data;
            })

        }
        catch(e){
            console.log(e);
        }
       
    }
    handleRowAction(event){
            // this.record = event.detail.row;
            const actionName = event.detail.action.name;
            console.log('actionName',actionName);
            const row = event.detail.row;
            console.log('row',JSON.stringify(row));
                switch (actionName) {
                    case 'View':
                        window.open(row.alternateLink, "_blank");
                    break;
                    case 'Download':
                        if(row.webContentLink){
                            console.log("row.webContentLink",row.webContentLink);
                            window.open(row.webContentLink, "_blank");
                        }
                        else{
                            let durl='https://docs.google.com/spreadsheets/export?id='+row.id+'&exportFormat=zip';
                            console.log("durl",durl);
                            window.open(durl, "_blank");
                        }
                    break;
                default:
            }
        }

    listView(event){
        // this.template.querySelectorAll('.')
        this.openListView=true;
        this.openGridView=false;

        event.target.classList.toggle('viewbutton');
    }
    gridView(event){
        this.openGridView=true;
        this.openListView=false;

        event.target.classList.toggle('viewbutton');
    }
    viewSelectedData(event){
        let index = event.target.dataset.index;
        console.log("row==>>",index);
        let selectedData=this.showdata[index];
        console.log(selectedData);
        window.open(selectedData.alternateLink, "_blank");
    }
    downloadSelectedData(event){
        let index = event.target.dataset.index;
        console.log("row==>>",index);
        let selectedData=this.showdata[index];
        console.log(selectedData);
        if(selectedData.webContentLink){
            console.log("selectedData.webContentLink",selectedData.webContentLink);
            window.open(selectedData.webContentLink, "_blank");
        }
        else{
            let durl='https://docs.google.com/spreadsheets/export?id='+selectedData.id+'&exportFormat=zip';
            console.log("durl",durl);
            window.open(durl, "_blank");
        }
    }
    // openfileUpload(event) {
    //     const file = event.target.files[0];
    //     var reader = new FileReader()
    //     reader.onload = () => {
    //         var base64 = reader.result.split(',')[1]
    //         this.fileData = {
    //             'filename': file.name,
    //             'base64': base64,
    //             'recordId': this.recordId
    //         }
    //         console.log(this.fileData)
    //     }
    //     reader.readAsDataURL(file)
    // }
    // handlefileSubmit(event){
    //     const {base64, filename, recordId} = this.fileData
        
    // }
    
    handleFilesChange(event){
        const uploadedFiles = event.detail.files[0];
        console.log("uploadedFiles",uploadedFiles);
        let reader = new FileReader();
        // let attachmentId = uploadedFiles[0].documentId;
        reader.onload = () => {
            var base64 = reader.result.split(',')[1];
            this.fileData = {
                'filename': uploadedFiles.name,
                'base64': base64,
                'type': uploadedFiles.type,
                // 'type': uploadedFiles.type,
                // 'size': uploadedFiles.size,

            }
            console.log("fileData",this.fileData);
        }
        reader.readAsDataURL(uploadedFiles);
    }
        // let code = this.accesstoken;
        // uploadFile({ attachmentId: attachmentId, accessToken:  code }).then(result=>{
        //     console.log("result",result);
            // this.fileData = null
            // let title = `${filename} uploaded successfully!!`
            // this.toast(title)
        // })

    // }
   async handlefileSubmit(event){
        this.isSpinner=true;
        const {base64, filename} = this.fileData;
        const type=this.fileData.type;
        console.log("type",type);
        await createContentVersion({ base64, filename}).then(result=>{
            this.fileData = null;
            console.log(result);
            console.log(result.VersionData);
            console.log(result.Id);
            this.cvId=result.Id;
        })
        console.log("outside");
       await uploadFile({ attachmentId: this.cvId, accessToken: this.accesstoken, type: type}).then(data=>{
        this.isSpinner=false;
        console.log('result',data);
        if(data == '200'){
            console.log("Inside");
              let title = 'uploaded successfully!!';
             this.toast(title)
        }
            // this.fileData = null
          
        })
    }
    toast(title){
        const toastEvent = new ShowToastEvent({
            title, 
            variant:"success"
        })
        this.dispatchEvent(toastEvent);
    }

    

   
}