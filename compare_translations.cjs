#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Read both JSON files
const enUsPath = path.join(__dirname, 'src/i18n/en_US.json');
const plPath = path.join(__dirname, 'src/i18n/pl.json');

try {
    const enUs = JSON.parse(fs.readFileSync(enUsPath, 'utf8'));
    const pl = JSON.parse(fs.readFileSync(plPath, 'utf8'));
    
    // Find missing keys in Polish translation
    const missingKeys = [];
    
    for (const key in enUs) {
        if (!(key in pl)) {
            missingKeys.push({
                key: key,
                enValue: enUs[key]
            });
        }
    }
    
    console.log(`Found ${missingKeys.length} missing translations in Polish file:`);
    console.log('=====================================');
    
    if (missingKeys.length > 0) {
        // Create the missing translations object
        const missingTranslations = {};
        missingKeys.forEach(item => {
            missingTranslations[item.key] = item.enValue; // Start with English as placeholder
            console.log(`"${item.key}": "${item.enValue}"`);
        });
        
        // Merge with existing Polish translations
        const updatedPl = { ...pl, ...missingTranslations };
        
        // Sort keys alphabetically
        const sortedPl = {};
        Object.keys(updatedPl).sort().forEach(key => {
            sortedPl[key] = updatedPl[key];
        });
        
        // Write back to Polish file
        fs.writeFileSync(plPath, JSON.stringify(sortedPl, null, 2), 'utf8');
        console.log('\n=====================================');
        console.log(`✅ Updated ${plPath} with ${missingKeys.length} missing keys`);
        console.log('Note: Missing translations are currently set to English values as placeholders.');
        console.log('Please translate them to Polish as needed.');
    } else {
        console.log('✅ No missing translations found! Polish file is up to date.');
    }
    
} catch (error) {
    console.error('Error processing translation files:', error.message);
    process.exit(1);
}
