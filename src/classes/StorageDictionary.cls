public class StorageDictionary {

    public static Map<String,String> DataByLanguage; 
    public static Set<String> DataNames;
    static {
        DataByLanguage=new Map<String,String>();
        DataByLanguage.put('en_US','Data Storage');
        DataByLanguage.put('de','Datenspeicher');
        DataByLanguage.put('es','Almacenamiento de datos');
        DataByLanguage.put('fr','Stockage de données');
        DataByLanguage.put('it','Memoria dati');
        DataByLanguage.put('ja','データストレージ');
        DataByLanguage.put('sv','Datalagring');
        DataByLanguage.put('ko','데이터 저장소');   
        DataByLanguage.put('zh_TW','資料儲存空間');
        DataByLanguage.put('zh_CN','数据存储');     
        DataByLanguage.put('pt_BR','Armazenamento de dados');     
        DataByLanguage.put('nl_NL','Gegevensopslag');     
        DataByLanguage.put('da','Datalagring');     
        DataByLanguage.put('th','พื้นที่เก็บข้อมูล');      
        DataByLanguage.put('fi','Tietojen tallennustila');     
        DataByLanguage.put('ru','Хранилище данных');     
        DataByLanguage.put('es_MX','Almacenamiento de datos');     
        DataByLanguage.put('no','Datalager');  
        
        DataNames=new Set<String>();
        DataNames.addAll(DataByLanguage.values());
    }
  
    public static Map<String,String> FileByLanguage;    	
    public static Set<String> FileNames;
    static {
        FileByLanguage=new Map<String,String>();
        FileByLanguage.put('en_US','File Storage');        
        FileByLanguage.put('de','Dateispeicher');
        FileByLanguage.put('es','Almacenamiento de archivos');        
        FileByLanguage.put('fr','Capacité de stockage des fichiers');        
        FileByLanguage.put('it','Memoria file');        
        FileByLanguage.put('ja','ファイルストレージ');        
        FileByLanguage.put('sv','Fillagring');        
        FileByLanguage.put('ko','파일 저장소');        
        FileByLanguage.put('zh_TW','檔案儲存空間');        
        FileByLanguage.put('zh_CN','文件存储');        
        FileByLanguage.put('pt_BR','Armazenamento de arquivos');     
        FileByLanguage.put('nl_NL','Bestandsopslag');     
        FileByLanguage.put('da','Fillagring'); 
        FileByLanguage.put('th','พื้นที่เก็บแฟ้ม');     
        FileByLanguage.put('fi','Tiedostojen tallennustila'); 
        FileByLanguage.put('ru','Хранилище файлов');     
        FileByLanguage.put('es_MX','Almacenamiento de archivos');  
        FileByLanguage.put('no','Fillager');     
        
        FileNames=new Set<String>();
        FileNames.addAll(FileByLanguage.values());        
    }
}